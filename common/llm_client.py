"""Cliente LLM com instrumentação manual para modo mock e auto-instrumentação OpenAI."""

from __future__ import annotations

import os
from typing import Any

from common.config import OPENAI_API_KEY, OPENAI_MODEL, USE_MOCK_LLM
from ddtrace.llmobs import LLMObs
from ddtrace.llmobs.decorators import llm


def _should_mock() -> bool:
    if USE_MOCK_LLM == "true":
        return True
    if USE_MOCK_LLM == "false":
        return False
    return not OPENAI_API_KEY


@llm(model_name=OPENAI_MODEL, model_provider="openai", name="retail-llm-inference")
def complete(messages: list[dict[str, str]], *, agent_role: str) -> str:
    if _should_mock():
        return _mock_completion(messages, agent_role=agent_role)

    from openai import OpenAI

    client = OpenAI(api_key=OPENAI_API_KEY)
    response = client.chat.completions.create(
        model=OPENAI_MODEL,
        messages=messages,
        temperature=0.2,
        max_tokens=600,
    )
    content = response.choices[0].message.content or ""
    usage = response.usage
    metrics: dict[str, Any] = {}
    if usage:
        metrics = {
            "input_tokens": usage.prompt_tokens,
            "output_tokens": usage.completion_tokens,
            "total_tokens": usage.total_tokens,
        }
    LLMObs.annotate(
        input_data=messages,
        output_data=[{"role": "assistant", "content": content}],
        metadata={"agent_role": agent_role, "model": OPENAI_MODEL},
        metrics=metrics,
    )
    return content


def _mock_completion(messages: list[dict[str, str]], *, agent_role: str) -> str:
    user_msg = next((m["content"] for m in reversed(messages) if m["role"] == "user"), "")
    if agent_role == "concierge":
        reply = (
            f"[Concierge] Recebi sua solicitação sobre: «{user_msg[:120]}». "
            "Encaminhei ao especialista de back-office para consultar pedidos e estoque."
        )
    else:
        reply = (
            f"[Especialista Retail] Com base nos dados internos, sobre «{user_msg[:120]}»: "
            "pedido #BR-10482 está em separação (previsão 2 dias úteis). "
            "Produto SKU-7781 com 14 unidades no CD São Paulo."
        )
    LLMObs.annotate(
        input_data=messages,
        output_data=[{"role": "assistant", "content": reply}],
        metadata={"agent_role": agent_role, "model": "mock-retail-llm"},
        metrics={"input_tokens": 42, "output_tokens": 88, "total_tokens": 130},
    )
    return reply
