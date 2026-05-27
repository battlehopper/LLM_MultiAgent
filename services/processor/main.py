"""Serviço APM: retail-processor — segundo agente (back-office)."""

from __future__ import annotations

import os
from contextlib import asynccontextmanager

from common.config import ML_APP_NAME
from common.datadog_setup import configure_observability
from ddtrace import patch
from ddtrace.llmobs import LLMObs
from fastapi import FastAPI, Request
from pydantic import BaseModel, Field
from services.processor.agent import run_specialist_agent

patch(fastapi=True)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    configure_observability()
    yield


app = FastAPI(
    title="Retail Processor",
    description="Agente especialista — processa conteúdo delegado pelo gateway",
    version="1.0.0",
    lifespan=lifespan,
)


class ProcessRequest(BaseModel):
    message: str
    session_id: str
    concierge_brief: str = Field(default="")


class ProcessResponse(BaseModel):
    answer: str
    specialist_summary: str


@app.middleware("http")
async def distributed_tracing_middleware(request: Request, call_next):
    """Ativa contexto distribuído ANTES de qualquer span (requisito LLMObs)."""
    LLMObs.activate_distributed_headers(dict(request.headers))
    return await call_next(request)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "service": os.getenv("DD_SERVICE", "retail-processor")}


@app.post("/process", response_model=ProcessResponse)
async def process(request: ProcessRequest) -> ProcessResponse:
    with LLMObs.workflow(
        name="retail-backoffice-process",
        session_id=request.session_id,
        ml_app=ML_APP_NAME,
    ):
        LLMObs.annotate(
            input_data=request.model_dump(),
            tags={"entrypoint": "gateway-delegation"},
        )
        result = run_specialist_agent(
            request.message,
            request.session_id,
            request.concierge_brief,
        )

    return ProcessResponse(
        answer=result["answer"],
        specialist_summary=result["specialist_summary"],
    )
