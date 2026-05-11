# Troubleshooting

Este documento cobre os problemas mais comuns ao operar o debuga-vllm-engine e suas soluções.

## Problemas de Inicialização

### vLLM não inicia: "CUDA out of memory"

O modelo não cabe na VRAM disponível.

**Diagnóstico:**
```bash
nvidia-smi  # Verificar VRAM livre
```

**Soluções:**

| Ação | Descrição |
|------|-----------|
| Usar modelo AWQ | Trocar para versão AWQ (ex.: `7B-Instruct-AWQ`) |
| Reduzir `max_model_len` | Diminuir de 8192 para 4096 ou 2048 |
| Reduzir `gpu_memory_utilization` | Diminuir de 0.9 para 0.85 |
| Reduzir `max_num_seqs` | Diminuir de 32 para 8 ou 4 |
| Liberar VRAM | Fechar outros processos GPU (`nvidia-smi` para identificar) |

### vLLM não inicia: "No module named 'vllm'"

O vLLM não está instalado no ambiente.

```bash
# Se usando Docker, verificar imagem
docker pull vllm/vllm-openai:latest

# Se instalação direta
pip install vllm
```

### vLLM não inicia: "NVIDIA driver too old"

O driver NVIDIA não é compatível com a versão do CUDA.

```bash
# Verificar versão do driver
nvidia-smi | head -3

# Atualizar driver (Ubuntu)
sudo apt-get update
sudo apt-get install -y nvidia-driver-535  # ou versão mais recente
sudo reboot
```

O driver mínimo recomendado é >= 525.60 para CUDA 12.x.

### Modelo não encontrado: "Repository not found"

O modelo não existe no Hugging Face ou requer autenticação.

```bash
# Verificar se HF_TOKEN está configurado
echo $HF_TOKEN

# Fazer login no Hugging Face
huggingface-cli login

# Verificar se o modelo existe
huggingface-cli repo info Qwen/Qwen2.5-Coder-7B-Instruct-AWQ
```

## Problemas de Performance

### Latência alta (> 5s para primeiro token)

**Possíveis causas e soluções:**

| Causa | Solução |
|-------|---------|
| Modelo muito grande para a GPU | Usar versão AWQ ou modelo menor |
| `max_model_len` muito alto | Reduzir para o mínimo necessário |
| Prefix caching desabilitado | Adicionar `--enable-prefix-caching` |
| GPU throttling (temperatura) | Verificar `nvidia-smi -q -d TEMPERATURE` |
| Muitos requests simultâneos | Reduzir `max_num_seqs` |

### Throughput baixo (< 10 tokens/s)

```bash
# Verificar utilização da GPU
watch -n 1 nvidia-smi

# Se GPU utilization < 50%, o bottleneck pode ser CPU ou I/O
# Se GPU utilization > 90%, o modelo está no limite da GPU
```

**Soluções:**
- Habilitar CUDA graphs (remover `--enforce-eager`)
- Aumentar `max_num_seqs` para melhor batching
- Usar quantização AWQ para liberar VRAM para batch maior

### KV-Cache cheio (requests na fila)

Quando `vllm:num_requests_waiting > 0` persistentemente:

```bash
# Verificar uso do cache
curl -s http://localhost:8000/metrics | grep gpu_cache_usage
```

**Soluções:**
- Reduzir `max_model_len` (libera espaço no KV-cache)
- Reduzir `max_num_seqs` (menos requests simultâneos)
- Aumentar `gpu_memory_utilization` (mais VRAM para cache)
- Usar modelo AWQ (menor footprint = mais cache)

## Problemas de Docker

### Container reiniciando em loop

```bash
# Verificar logs
docker logs debuga-vllm --tail 50

# Causas comuns:
# 1. CUDA out of memory → reduzir modelo/config
# 2. Modelo não encontrado → verificar MODEL_ID e HF_TOKEN
# 3. GPU não disponível → verificar nvidia-container-toolkit
```

### GPU não detectada no container

```bash
# Verificar NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi

# Se falhar, reinstalar toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Modelo demora para carregar

Na primeira execução, o modelo é baixado do Hugging Face. Isso pode levar vários minutos. O `start_period` do health check é de 120s para acomodar isso.

```bash
# Acompanhar progresso
docker logs -f debuga-vllm

# Para acelerar, pré-baixar o modelo
./scripts/download-model.sh 7b-awq
```

## Problemas de API

### Erro 503: "Model not ready"

O modelo ainda está carregando. Aguarde o health check passar:

```bash
# Verificar status
curl http://localhost:8000/health

# Aguardar modelo carregar (pode levar 1-3 minutos)
while ! curl -sf http://localhost:8000/health; do sleep 5; echo "Waiting..."; done
```

### Erro 400: "max_tokens exceeds model limit"

O `max_tokens` solicitado excede o `max_model_len` configurado.

```bash
# Verificar limite atual
curl -s http://localhost:8000/v1/models | python3 -m json.tool
```

Reduza `max_tokens` na requisição ou aumente `--max-model-len` no servidor.

### Respostas truncadas ou incompletas

O modelo atingiu o limite de tokens. Aumente `max_tokens` na requisição:

```json
{
  "max_tokens": 4096,
  "messages": [...]
}
```

Ou aumente `--max-model-len` no servidor (requer mais VRAM).

## Comandos Úteis de Diagnóstico

```bash
# Status da GPU
nvidia-smi

# Monitoramento contínuo da GPU
watch -n 1 nvidia-smi

# Temperatura e power
nvidia-smi -q -d TEMPERATURE,POWER

# Processos usando GPU
nvidia-smi --query-compute-apps=pid,name,used_memory --format=csv

# Health check do vLLM
./scripts/health-check.sh

# Logs do Docker
docker logs debuga-vllm --tail 100 -f

# Métricas do vLLM
curl -s http://localhost:8000/metrics | grep -E "^vllm:"

# Teste de inferência
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"test","messages":[{"role":"user","content":"ping"}],"max_tokens":5}'
```

## Referências

- [vLLM FAQ](https://docs.vllm.ai/en/latest/getting_started/faq.html)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
- [Hugging Face Hub Troubleshooting](https://huggingface.co/docs/huggingface_hub/troubleshooting)
