# debuga-vllm-engine

**Estudos de serving LLM com vLLM para workloads técnicos e inferência local acelerada por GPU.**

Desenvolvida por [Sperry Tecnologia](https://www.sperrytecnologia.com.br).

---

## O que é

Este repositório contém estudos e configurações experimentais para serving de modelos LLM com [vLLM](https://github.com/vllm-project/vllm), focado em cenários de alta concorrência e inferência local acelerada por GPU. O objetivo é avaliar a viabilidade de vLLM como alternativa ao Ollama para cenários enterprise com múltiplos usuários simultâneos.

Este é um repositório **experimental/laboratório**, não contém código de produção.

---

## Status

| Aspecto | Classificação |
|---------|--------------|
| Tipo | Laboratório de serving |
| Código de produção | Não incluso |
| Maturidade | Experimental |
| Uso atual na plataforma | Nenhum (Ollama é o runtime de produção) |

---

## Como se conecta à debuga.ai

A [debuga.ai](https://github.com/SperryTecnologia/debuga-ai) atualmente utiliza Ollama como runtime de inferência local. O vLLM é estudado como alternativa para cenários futuros que exijam:

- Alta concorrência (50+ usuários simultâneos)
- Continuous batching para melhor utilização de GPU
- Tensor parallelism para modelos maiores
- Compatibilidade nativa com API OpenAI

---

## Arquitetura

```
┌─────────────────────────────────────────┐
│            vLLM Engine                  │
│  ┌─────────────────────────────────┐    │
│  │  OpenAI-compatible API server   │    │
│  ├─────────────────────────────────┤    │
│  │  Continuous Batching Engine     │    │
│  ├─────────────────────────────────┤    │
│  │  PagedAttention (KV Cache)      │    │
│  ├─────────────────────────────────┤    │
│  │  GPU (CUDA / Tensor Parallel)   │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

---

## Funcionalidades Estudadas

| Feature | Descrição | Status |
|---------|-----------|--------|
| OpenAI-compatible endpoints | API drop-in replacement | Testado |
| Continuous batching | Processamento dinâmico de múltiplas requisições | Testado |
| PagedAttention | Gerenciamento eficiente de KV cache | Testado |
| Tensor parallelism | Distribuição de modelo entre GPUs | Planejado |
| Quantização (AWQ/GPTQ) | Modelos comprimidos para menor VRAM | Testado |
| Streaming | SSE-compatible streaming responses | Testado |
| Tool calling | Function calling via API | Em avaliação |

---

## Testes de Performance

Comparação indicativa entre Ollama e vLLM (Qwen 2.5 7B, RTX 3090):

| Métrica | Ollama | vLLM |
|---------|--------|------|
| Tokens/s (1 usuário) | ~45 | ~50 |
| Tokens/s (10 usuários) | ~15 | ~40 |
| Tokens/s (50 usuários) | Degradação | ~30 |
| First token latency | ~800ms | ~600ms |
| Utilização GPU (pico) | ~70% | ~95% |

> Resultados são indicativos e dependem do hardware, modelo e configuração.

---

## Quando usar vLLM vs Ollama

| Cenário | Recomendação |
|---------|-------------|
| Deploy simples, poucos usuários | Ollama |
| Prototipagem rápida | Ollama |
| Alta concorrência (50+) | vLLM |
| Múltiplas GPUs | vLLM |
| Modelos muito grandes (70B+) | vLLM |
| Máxima utilização de GPU | vLLM |

---

## Uso Previsto

- Avaliar vLLM para cenários enterprise da debuga.ai
- Documentar configurações de serving otimizadas
- Comparar performance com Ollama em diferentes cargas
- Preparar migração futura quando necessário

---

## Limitações

- vLLM tem setup mais complexo que Ollama
- Requer CUDA toolkit e drivers específicos
- Nem todos os modelos GGUF são suportados nativamente
- Overhead de memória maior para poucos usuários
- Este repositório não contém código de produção

---

## Roadmap

| Item | Status |
|------|--------|
| Setup básico com Qwen 2.5 | Concluído |
| Benchmarks comparativos | Concluído |
| Testes de concorrência | Em andamento |
| Tensor parallelism (multi-GPU) | Planejado |
| Integração com gateway | Planejado |
| Documentação de migração Ollama → vLLM | Planejado |

---

## Licença

Scripts e configurações sob licença MIT. O código de produção da plataforma é privado.

---

## Sperry Tecnologia

Desenvolvido por [Sperry Tecnologia](https://www.sperrytecnologia.com.br) — infraestrutura, segurança, DevOps e automação com IA.
