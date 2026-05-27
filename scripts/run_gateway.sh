#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

export PYTHONPATH="${PYTHONPATH:-.}"
export DD_SERVICE="${DD_SERVICE:-retail-gateway}"
export DD_LLMOBS_ML_APP="${DD_LLMOBS_ML_APP:-retail-assistant}"
export PROCESSOR_URL="${PROCESSOR_URL:-http://localhost:8002}"
export DD_LLMOBS_ENABLED="${DD_LLMOBS_ENABLED:-1}"
export DD_LLMOBS_AGENTLESS_ENABLED="${DD_LLMOBS_AGENTLESS_ENABLED:-auto}"
export DD_TRACE_ENABLED="${DD_TRACE_ENABLED:-1}"

exec ddtrace-run uvicorn services.gateway.main:app --host 0.0.0.0 --port "${GATEWAY_PORT:-8001}"
