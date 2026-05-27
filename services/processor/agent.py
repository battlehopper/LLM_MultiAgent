"""Agente de back-office: processa pedidos, estoque e políticas."""

from __future__ import annotations

from common.config import ML_APP_NAME
from common.llm_client import complete
from common.retail_data import RETAIL_CONTEXT
from ddtrace.llmobs import LLMObs
from ddtrace.llmobs.decorators import agent, retrieval, task


@retrieval(name="retail-knowledge-base", ml_app=ML_APP_NAME)
def fetch_retail_context(query: str) -> list[dict]:
    """Simula RAG sobre catálogo, pedidos e políticas."""
    documents = [
        {"id": "catalog", "text": RETAIL_CONTEXT},
        {"id": "query", "text": query},
    ]
    LLMObs.annotate(
        input_data={"query": query},
        output_data=documents,
        tags={"source": "mock-erp"},
    )
    return documents


@task(name="build-specialist-prompt", ml_app=ML_APP_NAME)
def build_prompt(message: str, concierge_brief: str, context_docs: list[dict]) -> list[dict]:
    context_blob = "\n".join(doc["text"] for doc in context_docs)
    return [
        {
            "role": "system",
            "content": (
                "Você é o especialista de operações retail (pedidos, estoque, trocas). "
                "Use apenas o contexto fornecido. Responda em português, de forma objetiva."
            ),
        },
        {
            "role": "user",
            "content": (
                f"Contexto interno:\n{context_blob}\n\n"
                f"Resumo do concierge: {concierge_brief}\n\n"
                f"Solicitação do cliente: {message}"
            ),
        },
    ]


@agent(name="retail-specialist", ml_app=ML_APP_NAME)
def run_specialist_agent(message: str, session_id: str, concierge_brief: str) -> dict:
    """Agente 2 — Especialista que processa e devolve a resposta final."""
    context_docs = fetch_retail_context(message)
    messages = build_prompt(message, concierge_brief, context_docs)
    answer = complete(messages, agent_role="specialist")

    LLMObs.annotate(
        input_data={
            "message": message,
            "session_id": session_id,
            "concierge_brief": concierge_brief,
        },
        output_data={"answer": answer},
        tags={"agent": "retail-specialist"},
    )

    return {
        "answer": answer,
        "specialist_summary": answer[:200] + ("..." if len(answer) > 200 else ""),
        "session_id": session_id,
    }
