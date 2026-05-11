# Monitoramento

Este documento cobre a configuração de monitoramento do vLLM com Prometheus e Grafana.

## Visão Geral

O vLLM expõe métricas no formato Prometheus em `/metrics`. O debuga-vllm-engine inclui configurações pré-definidas para coletar e visualizar essas métricas.

A stack de monitoramento é composta por:

| Componente | Função | Porta |
|------------|--------|-------|
| vLLM | Expõe métricas em `/metrics` | 8000 |
| Prometheus | Coleta e armazena métricas | 9090 |
| Grafana | Visualiza métricas em dashboards | 3000 |

## Iniciar com Monitoramento

O docker-compose inclui Prometheus e Grafana como profiles opcionais.

```bash
# Iniciar vLLM + Prometheus + Grafana
docker compose -f docker/docker-compose.yml --profile monitoring up -d

# Verificar status
docker compose -f docker/docker-compose.yml ps
```

## Métricas do vLLM

As métricas mais importantes expostas pelo vLLM estão organizadas na tabela abaixo.

### Métricas de Throughput

| Métrica | Descrição | Unidade |
|---------|-----------|---------|
| `vllm:avg_generation_throughput_toks_per_s` | Throughput médio de geração | tokens/s |
| `vllm:avg_prompt_throughput_toks_per_s` | Throughput médio de processamento de prompt | tokens/s |

### Métricas de Fila

| Métrica | Descrição | Alerta Sugerido |
|---------|-----------|----------------|
| `vllm:num_requests_running` | Requests em processamento | > 80% de `max_num_seqs` |
| `vllm:num_requests_waiting` | Requests na fila | > 0 por mais de 30s |
| `vllm:num_requests_swapped` | Requests com KV-cache em swap | > 0 (indica falta de VRAM) |

### Métricas de Cache

| Métrica | Descrição | Alerta Sugerido |
|---------|-----------|----------------|
| `vllm:gpu_cache_usage_perc` | Uso do KV-cache na GPU | > 90% |
| `vllm:cpu_cache_usage_perc` | Uso do KV-cache na CPU | > 50% |
| `vllm:gpu_prefix_cache_hit_rate` | Taxa de acerto do prefix cache | < 10% (prefix caching ineficaz) |

### Métricas de Latência

| Métrica | Descrição | Tipo |
|---------|-----------|------|
| `vllm:e2e_request_latency_seconds` | Latência end-to-end | Histograma |
| `vllm:time_to_first_token_seconds` | Time to first token (TTFT) | Histograma |
| `vllm:time_per_output_token_seconds` | Tempo por token de saída | Histograma |

## Configurar Prometheus

O arquivo `monitoring/prometheus.yml` já está configurado para coletar métricas do vLLM. Se o vLLM estiver rodando fora do Docker, ajuste o target:

```yaml
# monitoring/prometheus.yml
scrape_configs:
  - job_name: "vllm"
    static_configs:
      - targets: ["localhost:8000"]  # Ajustar se necessário
```

### Verificar Coleta

Acesse `http://localhost:9090/targets` para verificar se o Prometheus está coletando métricas do vLLM.

## Configurar Grafana

### Importar Dashboard

1. Acesse Grafana em `http://localhost:3000` (admin/admin)
2. Vá em **Dashboards** → **Import**
3. Faça upload do arquivo `monitoring/grafana-dashboard.json`
4. Selecione a data source Prometheus
5. Clique em **Import**

### Adicionar Data Source Prometheus

Se o Prometheus não estiver configurado automaticamente:

1. Vá em **Connections** → **Data Sources** → **Add data source**
2. Selecione **Prometheus**
3. URL: `http://prometheus:9090` (Docker) ou `http://localhost:9090` (local)
4. Clique em **Save & Test**

## Dashboard Incluído

O dashboard `monitoring/grafana-dashboard.json` inclui os seguintes painéis:

| Painel | Tipo | Descrição |
|--------|------|-----------|
| Requests Running | Stat | Número atual de requests em processamento |
| Requests Waiting | Stat | Número atual de requests na fila |
| GPU KV-Cache Usage | Gauge | Percentual de uso do KV-cache |
| Generation Throughput | Stat | Tokens/s de geração |
| Throughput Over Time | Time Series | Histórico de throughput |
| Request Queue | Time Series | Histórico de fila (running/waiting/swapped) |
| KV-Cache Usage | Time Series | Histórico de uso de cache |
| Prefix Cache Hit Rate | Time Series | Taxa de acerto do prefix cache |
| Request Latency | Time Series | Percentis de latência (p50/p90/p99) |

## Alertas (Opcional)

Para configurar alertas, adicione regras ao Prometheus ou use o Grafana Alerting. Exemplos de condições de alerta:

| Condição | Severidade | Ação |
|----------|-----------|------|
| `vllm:num_requests_waiting > 10` por 1min | Warning | Verificar carga |
| `vllm:gpu_cache_usage_perc > 0.95` por 5min | Critical | Reduzir `max_num_seqs` ou `max_model_len` |
| `vllm:num_requests_swapped > 0` por 1min | Warning | GPU com VRAM insuficiente |
| Health check falha por 30s | Critical | Reiniciar vLLM |

## Referências

- [vLLM Metrics](https://docs.vllm.ai/en/latest/serving/metrics.html)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
