"""Dados simulados do ecossistema retail para o agente especialista."""

RETAIL_CONTEXT = """
Catálogo (amostra):
- SKU-7781: Tênis Runner Pro — R$ 399,90 — estoque CD-SP: 14 un
- SKU-4420: Mochila Urban — R$ 189,90 — estoque CD-SP: 3 un (baixo)

Pedidos do cliente (CPF mascarado ***4821):
- BR-10482: 2x SKU-7781 — status: em_separacao — entrega prevista: 2 dias úteis
- BR-09811: 1x SKU-4420 — status: entregue — há 12 dias

Políticas:
- Troca em até 30 dias com nota fiscal
- Cashback 5% em compras acima de R$ 300
"""
