# Model Serving

Este documento cobre a configuração e operação do vLLM para servir modelos Qwen-Coder.

## API Compatível com OpenAI

O vLLM expõe uma API OpenAI-compatible. A compatibilidade é ampla, mas depende da versão, do endpoint e do modelo; valide os parâmetros usados pelo seu cliente.

### Endpoints Disponíveis

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/health` | GET | Health check do servidor |
| `/v1/models` | GET | Listar modelos carregados |
| `/v1/chat/completions` | POST | Chat completion (recomendado) |
| `/v1/completions` | POST | Text completion (legacy) |
| `/v1/embeddings` | POST | Embeddings (se suportado pelo modelo) |
| `/metrics` | GET | Métricas Prometheus |

### Chat Completions

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen2.5-Coder-7B-Instruct-AWQ",
    "messages": [
      {"role": "system", "content": "Você é um especialista em infraestrutura Linux."},
      {"role": "user", "content": "Como configurar rate limiting no Nginx?"}
    ],
    "temperature": 0.1,
    "max_tokens": 2048
  }'
```

### Streaming

Para respostas em tempo real, habilite streaming:

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen2.5-Coder-7B-Instruct-AWQ",
    "messages": [
      {"role": "user", "content": "Explique como funciona o tcpdump."}
    ],
    "stream": true,
    "max_tokens": 1024
  }'
```

### Com Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="not-needed"  # vLLM não requer API key por padrão
)

# Síncrono
response = client.chat.completions.create(
    model="Qwen/Qwen2.5-Coder-7B-Instruct-AWQ",
    messages=[
        {"role": "system", "content": "Você é um especialista em segurança."},
        {"role": "user", "content": "Analise estas regras de firewall."}
    ],
    temperature=0.1,
    max_tokens=2048
)
print(response.choices[0].message.content)

# Streaming
stream = client.chat.completions.create(
    model="Qwen/Qwen2.5-Coder-7B-Instruct-AWQ",
    messages=[
        {"role": "user", "content": "Escreva um script de backup."}
    ],
    stream=True,
    max_tokens=1024
)
for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

## Parâmetros de Geração

| Parâmetro | Descrição | Valor Padrão | Recomendado (DevOps) |
|-----------|-----------|-------------|---------------------|
| `temperature` | Aleatoriedade da geração | 1.0 | 0.1 (determinístico) |
| `top_p` | Nucleus sampling | 1.0 | 0.95 |
| `max_tokens` | Máximo de tokens na resposta | Modelo-dependente | 2048 |
| `frequency_penalty` | Penalidade por repetição | 0.0 | 0.0-0.3 |
| `presence_penalty` | Penalidade por novos tópicos | 0.0 | 0.0 |
| `stop` | Sequências de parada | Nenhuma | `["<|endoftext|>"]` |

Para avaliações controladas, uma temperatura baixa como `0.1` pode reduzir variação. Isso não torna a saída totalmente determinística nem substitui validação técnica.

## Configuração do Servidor

### Parâmetros do vLLM

Os parâmetros mais importantes para configurar o servidor estão documentados abaixo.

| Parâmetro | Descrição | Impacto |
|-----------|-----------|---------|
| `--max-model-len` | Contexto máximo (tokens) | Mais VRAM para contextos maiores |
| `--gpu-memory-utilization` | Fração da VRAM a usar | 0.9 é seguro; 0.95 para máximo |
| `--max-num-seqs` | Requests simultâneos | Mais concorrência = mais VRAM |
| `--enable-prefix-caching` | Cache de prefixos comuns | Reduz latência para prompts similares |
| `--tensor-parallel-size` | Número de GPUs | Distribui modelo entre GPUs |
| `--quantization` | Método de quantização | awq, gptq, fp8 |

### Usando Arquivos de Configuração

Os arquivos em `configs/` contêm configurações pré-definidas para cada modelo:

```bash
# Os configs são referência; o vLLM usa flags de linha de comando
# Use os valores do YAML como referência para seu .env

# Exemplo: aplicar config do 14B
grep -E "^  (max_model_len|max_num_seqs|gpu_memory_utilization)" configs/qwen-coder-14b.yaml
```

## LoRA Adapters

O vLLM suporta servir múltiplos adaptadores LoRA sobre o mesmo modelo base, sem recarregar o modelo.

```bash
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --enable-lora \
  --lora-modules \
    devops=./adapters/devops-lora \
    security=./adapters/security-lora \
  --max-lora-rank 16
```

Na API, especifique o adapter pelo nome:

```json
{
  "model": "devops",
  "messages": [...]
}
```

## Autenticação

Para proteger a API com uma chave, use o parâmetro `--api-key`:

```bash
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-Coder-7B-Instruct-AWQ \
  --api-key "sua-chave-aqui"
```

Os clientes devem incluir o header `Authorization: Bearer sua-chave-aqui`.

## Referências

- [vLLM Serving Docs](https://docs.vllm.ai/en/latest/serving/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference/chat)
