#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

export PYTHONPATH="${PYTHONPATH:-.}"
export DD_SERVICE="${DD_SERVICE:-retail-processor}"
export DD_LLMOBS_ML_APP="${DD_LLMOBS_ML_APP:-retail-assistant}"
export DD_LLMOBS_ENABLED="${DD_LLMOBS_ENABLED:-1}"
export DD_LLMOBS_AGENTLESS_ENABLED="${DD_LLMOBS_AGENTLESS_ENABLED:-auto}"
export DD_TRACE_ENABLED="${DD_TRACE_ENABLED:-1}"

exec ddtrace-run uvicorn services.processor.main:app --host 0.0.0.0 --port "${PROCESSOR_PORT:-8002}"
