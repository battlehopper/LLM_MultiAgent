"""Inicialização compartilhada de LLM Observability."""

from __future__ import annotations

import logging
import os

from common.config import ML_APP_NAME
from ddtrace.llmobs import LLMObs

logger = logging.getLogger(__name__)


def configure_observability() -> None:
    if os.getenv("DD_LLMOBS_ENABLED", "1") != "1":
        return
    if getattr(LLMObs, "enabled", False):
        return

    api_key = os.getenv("DD_API_KEY")
    site = os.getenv("DD_SITE", "datadoghq.com")
    mode = os.getenv("DD_LLMOBS_AGENTLESS_ENABLED", "auto").lower()

    if mode == "auto":
        agentless = bool(api_key)
    else:
        agentless = mode == "true"

    if agentless and not api_key:
        raise ValueError(
            "DD_API_KEY é obrigatório com DD_LLMOBS_AGENTLESS_ENABLED=true. "
            "Use o Datadog Agent (DD_LLMOBS_AGENTLESS_ENABLED=false) ou defina DD_API_KEY."
        )

    kwargs: dict = {
        "ml_app": ML_APP_NAME,
        "agentless_enabled": agentless,
    }
    if api_key:
        kwargs["api_key"] = api_key
        kwargs["site"] = site

    LLMObs.enable(**kwargs)
    logger.info(
        "LLM Observability ativo (ml_app=%s, agentless=%s)",
        ML_APP_NAME,
        agentless,
    )
