#!/usr/bin/env python3
"""Cliente de demonstração — envia uma pergunta ao gateway."""

from __future__ import annotations

import argparse
import json
import sys

import httpx


def main() -> int:
    parser = argparse.ArgumentParser(description="Demo retail multi-agent")
    parser.add_argument(
        "--url",
        default="http://localhost:8001",
        help="URL do retail-gateway",
    )
    parser.add_argument(
        "--message",
        default="Quero saber o status do pedido BR-10482 e se o tênis SKU-7781 ainda tem estoque.",
        help="Mensagem do usuário final",
    )
    parser.add_argument("--session-id", default=None, help="Session ID opcional")
    args = parser.parse_args()

    payload = {"message": args.message}
    if args.session_id:
        payload["session_id"] = args.session_id

    with httpx.Client(timeout=90.0) as client:
        response = client.post(f"{args.url.rstrip('/')}/chat", json=payload)
        response.raise_for_status()
        print(json.dumps(response.json(), indent=2, ensure_ascii=False))

    return 0


if __name__ == "__main__":
    sys.exit(main())
