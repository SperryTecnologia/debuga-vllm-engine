# Instalação do laboratório

## Escopo

Este guia prepara um ambiente de referência. Consulte sempre a documentação oficial atual
do Docker, do NVIDIA Container Toolkit e do vLLM antes da instalação.

## Pré-requisitos

- GPU NVIDIA suportada pelo engine e pelo modelo;
- driver compatível;
- Docker + Compose;
- NVIDIA Container Toolkit;
- armazenamento para pesos e cache;
- acesso ao model registry quando necessário.

## Verificação do runtime

Após instalar o toolkit conforme a documentação oficial da NVIDIA:

```bash
nvidia-smi
docker info
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
```

A tag CUDA é apenas exemplo; use uma imagem compatível com o driver do host.

## Configuração

```bash
git clone https://github.com/SperryTecnologia/debuga-vllm-engine.git
cd debuga-vllm-engine
cp .env.example .env
```

Revise:

- `MODEL_ID` e licença;
- `QUANTIZATION`;
- `MAX_MODEL_LEN`;
- `GPU_MEMORY_UTILIZATION`;
- `MAX_NUM_SEQS`;
- `VLLM_API_KEY`.

## Início com Docker

```bash
docker compose -f docker/docker-compose.yml config
docker compose -f docker/docker-compose.yml up -d vllm
docker compose -f docker/docker-compose.yml logs -f vllm
```

## Validação

```bash
./scripts/health-check.sh http://localhost:8000
curl -fsS http://localhost:8000/v1/models
```

## Monitoramento opcional

```bash
docker compose -f docker/docker-compose.yml --profile monitoring up -d
```

O exemplo contém credenciais padrão de Grafana e portas abertas. Ajuste antes de uso compartilhado.

## Instalação direta

A instalação Python varia conforme versão do vLLM, CUDA e GPU. Crie ambiente virtual e
siga a matriz oficial da versão selecionada. Depois use:

```bash
cp .env.example .env
./scripts/start-vllm.sh
```

## Evidência mínima

Registre commit, imagem, engine, modelo, GPU, driver, quantização e parâmetros usados.
