FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN chmod +x scripts/run_gateway.sh scripts/run_processor.sh

ENV PYTHONPATH=/app
ENV PROCESSOR_PORT=8002
ENV GATEWAY_PORT=8001

EXPOSE 8001 8002
