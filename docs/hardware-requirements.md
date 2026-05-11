# Requisitos de Hardware

Este documento detalha os requisitos de GPU, memória e armazenamento para cada modelo Qwen-Coder suportado pelo debuga-vllm-engine.

## Requisitos por Modelo

### Qwen2.5-Coder-7B

O modelo 7B é ideal para desenvolvimento, testes e ambientes com GPU limitada.

| Precisão | VRAM Necessária | GPU Mínima | GPU Recomendada | Throughput Estimado |
|----------|----------------|------------|-----------------|-------------------|
| AWQ (INT4) | ~4 GB | RTX 3060 (12 GB) | RTX 3090 (24 GB) | 40-60 tok/s |
| FP16 | ~14 GB | RTX 3090 (24 GB) | RTX 4090 (24 GB) | 30-50 tok/s |
| FP8 | ~8 GB | RTX 4090 (24 GB) | A10G (24 GB) | 35-55 tok/s |

### Qwen2.5-Coder-14B

O modelo 14B oferece o melhor equilíbrio entre qualidade e custo para tarefas de DevOps e segurança.

| Precisão | VRAM Necessária | GPU Mínima | GPU Recomendada | Throughput Estimado |
|----------|----------------|------------|-----------------|-------------------|
| AWQ (INT4) | ~8 GB | RTX 3090 (24 GB) | A10G (24 GB) | 25-40 tok/s |
| FP16 | ~28 GB | A100 40 GB | A100 80 GB | 20-35 tok/s |
| FP8 | ~16 GB | RTX 4090 (24 GB) | A100 40 GB | 22-38 tok/s |

### Qwen2.5-Coder-32B

O modelo 32B oferece máxima qualidade, mas requer hardware significativo. Recomendado para ambientes multi-GPU.

| Precisão | VRAM Necessária | GPU Mínima | GPU Recomendada | Throughput Estimado |
|----------|----------------|------------|-----------------|-------------------|
| AWQ (INT4) | ~18 GB | 2x RTX 3090 (48 GB) | 2x RTX 4090 (48 GB) | 15-25 tok/s |
| FP16 | ~64 GB | 2x A100 80 GB | 4x A100 40 GB | 12-20 tok/s |
| FP8 | ~36 GB | A100 80 GB | 2x A100 40 GB | 14-22 tok/s |

**Nota**: os valores de throughput são estimativas para geração com `max_tokens=512` e batch size 1. O throughput real varia com o hardware, configuração e carga.

## Requisitos de Sistema

Além da GPU, o sistema host deve atender aos seguintes requisitos.

| Componente | 7B | 14B | 32B |
|------------|-----|------|------|
| RAM | 16 GB | 32 GB | 64 GB |
| Disco (modelo) | ~4-14 GB | ~8-28 GB | ~18-64 GB |
| Disco (total) | 30 GB | 50 GB | 100 GB |
| CPU | 4 cores | 8 cores | 16 cores |
| Rede | 100 Mbps | 100 Mbps | 1 Gbps |

O disco deve ser SSD (NVMe preferível) para carregamento rápido do modelo.

## GPUs Compatíveis

O vLLM requer CUDA Compute Capability >= 7.0. As seguintes GPUs são compatíveis.

### GPUs de Consumo

| GPU | VRAM | Compute Capability | Modelo Máximo (AWQ) |
|-----|------|--------------------|---------------------|
| RTX 3060 | 12 GB | 8.6 | 7B |
| RTX 3070 Ti | 8 GB | 8.6 | 7B |
| RTX 3080 | 10 GB | 8.6 | 7B |
| RTX 3090 | 24 GB | 8.6 | 14B |
| RTX 4070 Ti | 12 GB | 8.9 | 7B |
| RTX 4080 | 16 GB | 8.9 | 14B |
| RTX 4090 | 24 GB | 8.9 | 14B |

### GPUs Profissionais / Data Center

| GPU | VRAM | Compute Capability | Modelo Máximo (FP16) |
|-----|------|--------------------|---------------------|
| A10G | 24 GB | 8.6 | 7B |
| A30 | 24 GB | 8.0 | 7B |
| A40 | 48 GB | 8.6 | 14B |
| A100 40 GB | 40 GB | 8.0 | 14B |
| A100 80 GB | 80 GB | 8.0 | 32B |
| H100 80 GB | 80 GB | 9.0 | 32B |
| L40S | 48 GB | 8.9 | 14B |

### Multi-GPU (Tensor Parallelism)

| Configuração | VRAM Total | Modelo Máximo (FP16) |
|-------------|-----------|---------------------|
| 2x RTX 3090 | 48 GB | 14B |
| 2x RTX 4090 | 48 GB | 14B |
| 2x A100 40 GB | 80 GB | 32B |
| 2x A100 80 GB | 160 GB | 32B (batch grande) |
| 4x A100 40 GB | 160 GB | 32B (batch grande) |
| 8x A100 80 GB | 640 GB | 32B (máximo throughput) |

## Dimensionamento para Carga

A tabela abaixo estima o hardware necessário para diferentes níveis de carga concorrente.

| Usuários Simultâneos | Modelo Sugerido | Hardware Sugerido |
|---------------------|----------------|-------------------|
| 1-5 (dev/teste) | 7B AWQ | 1x RTX 3090 |
| 5-15 (equipe) | 14B AWQ | 1x A100 40 GB |
| 15-50 (departamento) | 14B AWQ | 2x A100 40 GB |
| 50+ (produção) | 32B AWQ | 4x A100 80 GB |

**Nota**: estes são valores estimados para cenários de laboratório. O dimensionamento de produção depende do padrão de uso real (tamanho dos prompts, frequência, concorrência).

## Referências

- [vLLM Supported Hardware](https://docs.vllm.ai/en/latest/getting_started/installation.html)
- [NVIDIA CUDA GPUs](https://developer.nvidia.com/cuda-gpus)
- [Qwen2.5-Coder Model Cards](https://huggingface.co/collections/Qwen/qwen25-coder-66eaa22e6f99801bf65b0c2f)
