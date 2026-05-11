# Quantização

A quantização reduz a precisão dos pesos do modelo para diminuir o consumo de VRAM e aumentar o throughput. Este documento cobre os métodos suportados pelo vLLM para modelos Qwen-Coder.

## Métodos Suportados

| Método | Precisão | Qualidade | Velocidade | Suporte vLLM |
|--------|----------|-----------|------------|-------------|
| **AWQ** | INT4 | Alta | Rápida | Nativo |
| **GPTQ** | INT4 | Alta | Rápida | Nativo |
| **FP8** | 8-bit | Muito alta | Rápida | Nativo (Hopper/Ada) |
| **BitsAndBytes** | NF4/INT8 | Alta | Média | Via integração |

A recomendação para produção com vLLM é **AWQ**, por oferecer o melhor equilíbrio entre qualidade, velocidade e compatibilidade.

## AWQ (Activation-aware Weight Quantization)

O AWQ é o método recomendado para deploy com vLLM. Ele preserva os canais mais importantes do modelo durante a quantização, resultando em perda mínima de qualidade.

### Modelos AWQ Pré-quantizados

A Qwen disponibiliza versões AWQ oficiais no Hugging Face. Usar modelos pré-quantizados é a forma mais simples.

```bash
# Baixar modelo AWQ
./scripts/download-model.sh 7b-awq

# Servir com vLLM
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-Coder-7B-Instruct-AWQ \
  --quantization awq \
  --max-model-len 8192
```

### Economia de VRAM

| Modelo | FP16 | AWQ (INT4) | Redução |
|--------|------|-----------|---------|
| 7B | ~14 GB | ~4 GB | 71% |
| 14B | ~28 GB | ~8 GB | 71% |
| 32B | ~64 GB | ~18 GB | 72% |

## GPTQ

O GPTQ é uma alternativa ao AWQ com qualidade similar. A principal diferença é o algoritmo de quantização (baseado em Hessiana).

```bash
# Servir modelo GPTQ
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-Coder-7B-Instruct-GPTQ-Int4 \
  --quantization gptq \
  --max-model-len 8192
```

## FP8 (Hopper/Ada GPUs)

Para GPUs com suporte nativo a FP8 (H100, L40S, RTX 4090), o FP8 oferece qualidade quase idêntica a FP16 com ~50% menos VRAM.

```bash
# Quantização FP8 on-the-fly
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --quantization fp8 \
  --max-model-len 8192
```

O FP8 não requer modelos pré-quantizados; o vLLM converte automaticamente durante o carregamento.

## Quando Usar Cada Método

| Cenário | Método Recomendado | Motivo |
|---------|-------------------|--------|
| GPU com pouca VRAM (8-12 GB) | AWQ | Máxima economia de memória |
| GPU com VRAM moderada (24 GB) | AWQ ou FP16 | AWQ para modelo maior, FP16 para máxima qualidade |
| GPU Hopper/Ada (H100, L40S) | FP8 | Qualidade próxima a FP16, boa economia |
| Máxima qualidade | FP16 | Sem perda de precisão |
| Máximo throughput | AWQ | Menor VRAM = mais espaço para batch |
| Fine-tuning (treino) | BitsAndBytes NF4 | QLoRA com PEFT |

## Impacto na Qualidade

Para tarefas de DevOps e segurança, a diferença entre AWQ e FP16 é geralmente imperceptível. O modelo 14B em AWQ frequentemente supera o 7B em FP16, usando VRAM similar.

A recomendação geral é: **use o maior modelo que cabe na sua GPU com AWQ**, em vez de um modelo menor em FP16.

## Referências

- [vLLM Quantization](https://docs.vllm.ai/en/latest/quantization/)
- [AutoAWQ](https://github.com/casper-hansen/AutoAWQ)
- [GPTQ](https://github.com/IST-DASLab/gptq)
