# Instalação

Este guia cobre a instalação do debuga-vllm-engine para ambiente de laboratório local.

## Pré-requisitos

O debuga-vllm-engine requer uma GPU NVIDIA com suporte a CUDA. A tabela abaixo resume os requisitos de sistema.

| Componente | Requisito Mínimo |
|------------|-----------------|
| GPU | NVIDIA com CUDA Compute Capability >= 7.0 (Volta+) |
| Driver NVIDIA | >= 525.60 |
| VRAM | 8 GB (7B AWQ) a 80 GB (32B FP16) |
| RAM | 16 GB |
| Disco | 20 GB livres (modelo + dependências) |
| SO | Ubuntu 20.04+ / Debian 11+ / RHEL 8+ |

## Opção 1: Docker (Recomendado)

A forma mais simples de rodar o vLLM é via Docker com NVIDIA Container Toolkit.

### 1.1. Instalar Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Fazer logout e login novamente
```

### 1.2. Instalar NVIDIA Container Toolkit

```bash
# Adicionar repositório NVIDIA
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L "https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list" | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Instalar
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configurar Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### 1.3. Verificar GPU no Docker

```bash
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
```

Se a saída mostrar sua GPU, a instalação está correta.

### 1.4. Configurar e Iniciar

```bash
git clone https://github.com/SperryTecnologia/debuga-vllm-engine.git
cd debuga-vllm-engine

# Configurar variáveis de ambiente
cp .env.example .env
# Editar .env: definir HF_TOKEN e MODEL_ID

# Iniciar
docker compose -f docker/docker-compose.yml up -d

# Verificar logs
docker compose -f docker/docker-compose.yml logs -f vllm
```

O modelo será baixado automaticamente na primeira execução. Isso pode levar alguns minutos dependendo da conexão.

### 1.5. Iniciar com Monitoramento (Opcional)

```bash
# Inclui Prometheus + Grafana
docker compose -f docker/docker-compose.yml --profile monitoring up -d
```

O Grafana estará disponível em `http://localhost:3000` (admin/admin).

## Opção 2: Instalação Direta (sem Docker)

Para ambientes onde Docker não está disponível ou não é desejado.

### 2.1. Instalar CUDA Toolkit

```bash
# Ubuntu 22.04 — CUDA 12.4
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-4
```

### 2.2. Criar Ambiente Python

```bash
# Python 3.10+ necessário
python3 -m venv .venv
source .venv/bin/activate

# Instalar vLLM
pip install vllm

# Instalar Hugging Face CLI
pip install huggingface_hub[cli]
```

### 2.3. Baixar Modelo e Iniciar

```bash
# Configurar
cp .env.example .env
# Editar .env

# Baixar modelo
./scripts/download-model.sh 7b-awq

# Iniciar vLLM
./scripts/start-vllm.sh
```

## Verificação

Após a instalação, verifique que tudo está funcionando:

```bash
# Health check completo
./scripts/health-check.sh

# Teste rápido de inferência
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen2.5-Coder-7B-Instruct-AWQ",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

## Próximos Passos

Após a instalação, consulte os seguintes guias:

- [Hardware Requirements](hardware-requirements.md) para dimensionamento
- [Model Serving](model-serving.md) para configuração avançada
- [Monitoring](monitoring.md) para configurar Prometheus e Grafana
