# debuga-vllm-engine

Configurações e scripts para rodar [vLLM](https://github.com/vllm-project/vllm) com modelos [Qwen-Coder](https://huggingface.co/collections/Qwen/qwen25-coder-66eaa22e6f99801bf65b0c2f) em GPU. Parte da stack LLM do [debuga.ai](https://debuga.ai).

## Sobre

O **debuga-vllm-engine** é um laboratório público para configurar e operar o vLLM como engine de inferência para modelos Qwen-Coder, voltados a tarefas de DevOps, segurança da informação e infraestrutura de TI.

Este repositório contém:

- Dockerfile e docker-compose para ambiente local com CUDA 12
- Configurações YAML para modelos Qwen-Coder (7B, 14B, 32B)
- Scripts utilitários (download, inicialização, health check, benchmark)
- Configuração de monitoramento com Prometheus e Grafana
- Documentação de instalação, hardware, serving, quantização e troubleshooting

### O que este repositório **não** contém

- Pesos de modelos (devem ser baixados do Hugging Face)
- Dados de clientes ou conversas reais
- Configurações de produção do debuga.ai
- Secrets, tokens ou credenciais
- Adaptadores LoRA ou fine-tuning proprietário
- Métricas ou custos reais de produção

## Atribuição

Este projeto é **baseado em vLLM** e **compatível com Qwen-Coder**. Tanto o vLLM quanto os modelos Qwen são projetos upstream independentes, desenvolvidos por suas respectivas equipes. Este repositório apenas fornece configurações e scripts para facilitar o uso desses projetos.

## Requisitos de GPU

| Modelo | Precisão | VRAM Mínima | GPU Recomendada |
|--------|----------|-------------|-----------------|
| Qwen2.5-Coder-7B | AWQ (INT4) | 8 GB | RTX 3060 12 GB |
| Qwen2.5-Coder-7B | FP16 | 16 GB | RTX 3090 / 4090 |
| Qwen2.5-Coder-14B | AWQ (INT4) | 12 GB | RTX 3090 / 4090 |
| Qwen2.5-Coder-14B | FP16 | 32 GB | A100 40 GB |
| Qwen2.5-Coder-32B | AWQ (INT4) | 20 GB | RTX 3090 / A10G |
| Qwen2.5-Coder-32B | FP16 | 68 GB | A100 80 GB |

**Requisitos de sistema:**
- NVIDIA GPU com CUDA Compute Capability >= 7.0 (Volta ou superior)
- NVIDIA Driver >= 525.60
- Docker com NVIDIA Container Toolkit (para uso com Docker)
- Ou: Python 3.10+, CUDA 12.x, PyTorch 2.x (para uso direto)

## Quick Start

### 1. Clonar e configurar

```bash
git clone https://github.com/SperryTecnologia/debuga-vllm-engine.git
cd debuga-vllm-engine
cp .env.example .env
# Editar .env com seu HF_TOKEN e configurações desejadas
```

### 2. Baixar modelo

```bash
./scripts/download-model.sh 7b-awq
```

### 3. Iniciar vLLM

```bash
# Com Docker (recomendado)
docker compose -f docker/docker-compose.yml up -d

# Ou diretamente
./scripts/start-vllm.sh
```

### 4. Verificar status

```bash
./scripts/health-check.sh
```

### 5. Usar a API

A API é compatível com o formato OpenAI:

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen2.5-Coder-7B-Instruct-AWQ",
    "messages": [
      {"role": "system", "content": "Você é um especialista em infraestrutura Linux."},
      {"role": "user", "content": "Como diagnosticar alta latência em um servidor web Nginx?"}
    ],
    "temperature": 0.1,
    "max_tokens": 1024
  }'
```

### Com Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="not-needed"
)

response = client.chat.completions.create(
    model="Qwen/Qwen2.5-Coder-7B-Instruct-AWQ",
    messages=[
        {"role": "system", "content": "Você é um especialista em segurança."},
        {"role": "user", "content": "Analise as regras iptables deste servidor."}
    ],
    temperature=0.1
)

print(response.choices[0].message.content)
```

## Estrutura do Repositório

```
debuga-vllm-engine/
├── README.md                          # Este arquivo
├── LICENSE                            # Apache 2.0
├── THIRD_PARTY_LICENSES               # Licenças de projetos upstream
├── .gitignore                         # Ignora modelos, secrets, cache
├── .env.example                       # Template de variáveis de ambiente
├── docker/
│   ├── Dockerfile.cuda12              # Imagem Docker com CUDA 12 + vLLM
│   └── docker-compose.yml             # Compose para lab local
├── configs/
│   ├── qwen-coder-7b.yaml            # Config para 7B (single GPU)
│   ├── qwen-coder-14b.yaml           # Config para 14B (single/multi GPU)
│   └── qwen-coder-32b.yaml           # Config para 32B (multi GPU)
├── scripts/
│   ├── download-model.sh             # Baixar modelos do Hugging Face
│   ├── start-vllm.sh                 # Iniciar vLLM com .env
│   ├── health-check.sh               # Verificar status do engine
│   └── benchmark.sh                  # Benchmark com prompts sintéticos
├── monitoring/
│   ├── prometheus.yml                 # Scrape config para vLLM
│   └── grafana-dashboard.json         # Dashboard de métricas
└── docs/
    ├── installation.md                # Guia de instalação
    ├── hardware-requirements.md       # Requisitos detalhados de GPU
    ├── model-serving.md               # Serving e API
    ├── quantization.md                # Guia de quantização
    ├── monitoring.md                  # Monitoramento com Prometheus/Grafana
    └── troubleshooting.md             # Problemas comuns e soluções
```

## Documentação

| Documento | Descrição |
|-----------|-----------|
| [Instalação](docs/installation.md) | Pré-requisitos, Docker, instalação direta |
| [Hardware](docs/hardware-requirements.md) | Requisitos de GPU por modelo e precisão |
| [Model Serving](docs/model-serving.md) | Configuração, API, streaming, LoRA |
| [Quantização](docs/quantization.md) | AWQ, GPTQ, FP8 — quando usar cada um |
| [Monitoramento](docs/monitoring.md) | Prometheus, Grafana, alertas |
| [Troubleshooting](docs/troubleshooting.md) | Problemas comuns e soluções |

## Repositórios Relacionados

| Repositório | Descrição |
|-------------|-----------|
| [debuga-ai](https://github.com/SperryTecnologia/debuga-ai) | Plataforma SaaS principal |
| [debuga-llm-stack](https://github.com/SperryTecnologia/debuga-llm-stack) | Arquitetura da stack LLM |
| [debuga-qwen-coder-lab](https://github.com/SperryTecnologia/debuga-qwen-coder-lab) | Lab de avaliação de modelos Qwen-Coder |
| **debuga-vllm-engine** | Este repositório — engine de inferência |
| debuga-llm-gateway | Gateway de roteamento LLM (em breve) |

## Segurança

- Este repositório **não contém** secrets, credenciais ou configurações de produção
- Todos os IPs usados em exemplos são de ranges privados RFC 1918 (10.0.x.x, 192.168.x.x)
- Pesos de modelos devem ser baixados separadamente do Hugging Face
- Para reportar vulnerabilidades: security@sperrytecnologia.com.br

## Licença

Este projeto está licenciado sob [Apache License 2.0](LICENSE).

Os modelos Qwen-Coder são licenciados sob seus próprios termos (ver [Qwen License](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct/blob/main/LICENSE)). O vLLM é licenciado sob Apache 2.0. Consulte [THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES) para detalhes.
