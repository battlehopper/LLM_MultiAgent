import os

ML_APP_NAME = os.getenv("DD_LLMOBS_ML_APP", "retail-assistant")
GATEWAY_SERVICE = os.getenv("DD_SERVICE", "retail-gateway")
PROCESSOR_URL = os.getenv("PROCESSOR_URL", "http://localhost:8002")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
USE_MOCK_LLM = os.getenv("USE_MOCK_LLM", "auto").lower()
