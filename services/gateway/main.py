"""Serviço APM: retail-gateway — ponto de entrada do usuário final."""

from __future__ import annotations

import os
import uuid
from contextlib import asynccontextmanager

from common.config import ML_APP_NAME
from common.datadog_setup import configure_observability
from ddtrace import patch
from ddtrace.llmobs import LLMObs
from fastapi import FastAPI
from pydantic import BaseModel, Field
from services.gateway.agent import run_concierge_agent

patch(fastapi=True, httpx=True)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    configure_observability()
    yield


app = FastAPI(
    title="Retail Gateway",
    description="Agente concierge — recebe interação do usuário e delega ao especialista",
    version="1.0.0",
    lifespan=lifespan,
)


class ChatRequest(BaseModel):
    message: str = Field(..., examples=["Onde está meu pedido BR-10482?"])
    session_id: str | None = Field(
        default=None,
        description="ID de sessão para agrupar traces no LLM Observability",
    )


class ChatResponse(BaseModel):
    answer: str
    session_id: str
    concierge_brief: str
    specialist_summary: str
    trace_hint: str


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "service": os.getenv("DD_SERVICE", "retail-gateway")}


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    session_id = request.session_id or f"session-{uuid.uuid4().hex[:12]}"

    with LLMObs.workflow(
        name="retail-customer-chat",
        session_id=session_id,
        ml_app=ML_APP_NAME,
    ):
        LLMObs.annotate(
            input_data={"message": request.message},
            tags={"entrypoint": "user", "channel": "web"},
        )
        result = await run_concierge_agent(request.message, session_id)

    return ChatResponse(
        answer=result["answer"],
        session_id=session_id,
        concierge_brief=result["concierge_brief"],
        specialist_summary=result["specialist_summary"],
        trace_hint=(
            "Trace unificado no Datadog LLM Observability (ml_app=retail-assistant) "
            "com spans APM em retail-gateway → retail-processor"
        ),
    )
