<p align="center">
  <img src="https://debuga.ai/favicon.ico" width="84" alt="debuga.ai" />
</p>

<h1 align="center">debuga.ai vLLM Engine</h1>

<p align="center">
  <strong>Deployment público de referência para serving de modelos em GPU NVIDIA</strong>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> ·
  <a href="docs/installation.md">Instalação</a> ·
  <a href="docs/model-serving.md">Serving</a> ·
  <a href="docs/monitoring.md">Monitoramento</a> ·
  <a href="SECURITY.md">Segurança</a>
</p>

<p align="center">
  <img alt="Status" src="https://img.shields.io/badge/status-reference%20deployment-7c3aed" />
  <img alt="Engine" src="https://img.shields.io/badge/engine-vLLM-1f6feb" />
  <img alt="Hardware" src="https://img.shields.io/badge/hardware-NVIDIA%20GPU-76b900" />
  <img alt="Licença" src="https://img.shields.io/badge/licen%C3%A7a-Apache--2.0-6e7681" />
</p>

---

> [!IMPORTANT]
> Este é um **deployment de referência para laboratório**. A produção atual documentada do
> debuga.ai não depende deste repositório como topologia obrigatória. Modelos, imagens,
> performance e capacidade devem ser homologados no hardware-alvo.

## Visão geral

O projeto reúne exemplos de configuração, scripts operacionais, Compose e monitoramento
para expor um modelo por uma API compatível com clientes OpenAI. O foco é facilitar um
laboratório reproduzível, não oferecer uma imagem enterprise pronta.

```mermaid
flowchart LR
  CLIENT[Cliente OpenAI-compatible] --> API[vLLM API Server]
  API --> SCHED[Scheduler / batching]
  SCHED --> GPU[NVIDIA GPU]
  API --> METRICS[/metrics]
  METRICS --> PROM[Prometheus]
  PROM --> GRAF[Grafana]
```

## Conteúdo e maturidade

| Componente | Estado | Observação |
|---|---|---|
| Compose vLLM | Referência executável | usa imagem de exemplo |
| Configurações 7B/14B/32B | Ponto de partida | não homologadas universalmente |
| Download de modelo | Script utilitário | depende do Hugging Face |
| Start direto | Script utilitário | requer vLLM instalado |
| Health check | Script funcional | valida conectividade e inferência curta |
| Benchmark sintético | Ferramenta inicial | mede transporte/latência, não qualidade |
| Prometheus | Exemplo | métricas dependem da versão do vLLM |
| Grafana | Dashboard de referência | revisar queries com a versão instalada |
| SLA/capacidade | Não definido | requer teste de carga |

## Quick Start

### Pré-requisitos

- host Linux compatível;
- driver NVIDIA;
- Docker e Docker Compose;
- NVIDIA Container Toolkit;
- modelo cuja licença permita o uso pretendido.

Siga a documentação oficial atual do NVIDIA Container Toolkit para instalação do runtime.

```bash
git clone https://github.com/SperryTecnologia/debuga-vllm-engine.git
cd debuga-vllm-engine
cp .env.example .env
```

Revise `.env`, especialmente `MODEL_ID`, quantização, contexto e uso de GPU.

```bash
docker compose -f docker/docker-compose.yml config
docker compose -f docker/docker-compose.yml up -d vllm
docker compose -f docker/docker-compose.yml logs -f vllm
```

Validação:

```bash
./scripts/health-check.sh http://localhost:8000
curl -fsS http://localhost:8000/v1/models
```

Monitoramento opcional:

```bash
docker compose -f docker/docker-compose.yml --profile monitoring up -d
```

> [!CAUTION]
> O exemplo pode operar sem API key e expõe portas. Restrinja rede, configure autenticação,
> use TLS em proxy reverso e remova senhas padrão antes de qualquer ambiente compartilhado.

## Serving

A API e os parâmetros suportados dependem da versão do vLLM e do modelo. Este repositório
usa como referência:

- health check;
- listagem de modelos;
- chat completions;
- streaming;
- métricas em `/metrics` quando disponíveis.

Consulte [Model Serving](docs/model-serving.md).

## Desempenho: como publicar resultados

Não há uma comparação universal entre vLLM, Ollama, TGI ou llama.cpp. Resultados válidos
precisam registrar:

```text
engine e versão
imagem/container digest
modelo e revisão
quantização
GPU, driver e CUDA
contexto e tamanho de saída
concorrência
warm-up
número de execuções
dados brutos
```

Use o script sintético como ponto de partida:

```bash
./scripts/benchmark.sh http://localhost:8000 10
```

Ele mede latência e tokens reportados pelo endpoint; não avalia correção técnica da resposta.

## Estrutura

```text
debuga-vllm-engine/
├── configs/
├── docker/
├── docs/
├── monitoring/
├── scripts/
├── .env.example
└── README.md
```

## Documentação

| Documento | Conteúdo |
|---|---|
| [Instalação](docs/installation.md) | Preparação e início do laboratório |
| [Hardware](docs/hardware-requirements.md) | Critérios de dimensionamento |
| [Serving](docs/model-serving.md) | API e parâmetros |
| [Quantização](docs/quantization.md) | Trade-offs e validação |
| [Monitoramento](docs/monitoring.md) | Métricas e dashboard |
| [Troubleshooting](docs/troubleshooting.md) | Diagnóstico inicial |

## Ecossistema público

| Projeto | Papel |
|---|---|
| [debuga-ai](https://github.com/SperryTecnologia/debuga-ai) | Produto e documentação oficial |
| [debuga-llm-stack](https://github.com/SperryTecnologia/debuga-llm-stack) | Arquitetura de referência |
| [debuga-llm-gateway](https://github.com/SperryTecnologia/debuga-llm-gateway) | Roteamento local/cloud |
| [debuga-vllm-engine](https://github.com/SperryTecnologia/debuga-vllm-engine) | Este deployment de referência |
| [debuga-qwen-coder-lab](https://github.com/SperryTecnologia/debuga-qwen-coder-lab) | Avaliação de modelos |

## Licença

Código, scripts e documentação sob [Apache License 2.0](LICENSE). Modelos, imagens e
ferramentas de terceiros mantêm suas próprias licenças.

## Sperry Tecnologia

- Plataforma: [debuga.ai](https://debuga.ai)
- Contato: contato@sperrytecnologia.com.br
