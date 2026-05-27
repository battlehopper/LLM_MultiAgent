"""Agente de front-office: recebe o usuário e delega ao especialista."""

from __future__ import annotations

import httpx
from common.config import ML_APP_NAME, PROCESSOR_URL
from common.llm_client import complete
from ddtrace.llmobs import LLMObs
from ddtrace.llmobs.decorators import agent, task
from pydantic import BaseModel


class ProcessorResponse(BaseModel):
    answer: str
    specialist_summary: str


@task(name="enrich-user-intent", ml_app=ML_APP_NAME)
def enrich_intent(user_message: str) -> str:
    """Normaliza a intenção antes de delegar ao segundo agente."""
    normalized = user_message.strip()
    LLMObs.annotate(
        input_data={"message": user_message},
        output_data={"normalized": normalized},
        tags={"retail_channel": "ecommerce"},
    )
    return normalized


@agent(name="retail-concierge", ml_app=ML_APP_NAME)
async def run_concierge_agent(user_message: str, session_id: str) -> dict:
    """
    Agente 1 — Concierge retail.
    Entende a solicitação do cliente e repassa ao serviço do Agente 2.
    """
    intent = enrich_intent(user_message)

    concierge_messages = [
        {
            "role": "system",
            "content": (
                "Você é o concierge de uma rede varejista omnichannel. "
                "Resuma em uma frase o que o cliente precisa antes de escalar ao especialista."
            ),
        },
        {"role": "user", "content": intent},
    ]
    concierge_brief = complete(concierge_messages, agent_role="concierge")

    headers: dict[str, str] = {"content-type": "application/json"}
    headers = LLMObs.inject_distributed_headers(headers)

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            f"{PROCESSOR_URL}/process",
            json={
                "message": intent,
                "session_id": session_id,
                "concierge_brief": concierge_brief,
            },
            headers=headers,
        )
        response.raise_for_status()
        payload = ProcessorResponse.model_validate(response.json())

    final_answer = (
        f"{payload.answer}\n\n"
        f"— Encaminhado pelo concierge: {concierge_brief}"
    )

    LLMObs.annotate(
        input_data={"user_message": user_message, "session_id": session_id},
        output_data={"answer": final_answer},
        tags={"agent": "retail-concierge", "downstream_service": "retail-processor"},
    )

    return {
        "answer": final_answer,
        "concierge_brief": concierge_brief,
        "specialist_summary": payload.specialist_summary,
        "session_id": session_id,
    }
