# Requisitos de hardware

## Dimensionamento responsável

A VRAM necessária é composta por pesos, runtime, KV-cache e buffers. O tamanho nominal dos
pesos não representa a memória total. Contexto e concorrência podem alterar fortemente o consumo.

## Classes de referência

| Classe de GPU | Ponto de partida | Limitações típicas |
|---|---|---|
| 8–12 GB | modelos menores/quantizados | contexto e concorrência reduzidos |
| 16–24 GB | modelos médios quantizados | validar KV-cache e OOM |
| 40–48 GB | maior contexto ou modelos maiores | custo e energia maiores |
| 80 GB+ / multi-GPU | modelos grandes e tensor parallel | complexidade de rede e operação |

## Processo

1. confirme a model card e a licença;
2. escolha precisão/quantização;
3. defina contexto máximo realista;
4. comece com `max_num_seqs` baixo;
5. execute warm-up;
6. aumente concorrência gradualmente;
7. registre OOM, fila, TTFT e latência.

## Recursos do host

- RAM suficiente para download, carregamento e operações auxiliares;
- SSD/NVMe para reduzir tempo de carga;
- espaço maior que o tamanho dos pesos;
- refrigeração e alimentação adequadas;
- rede compatível com o volume de requests e downloads.

## Sobre throughput e usuários

Não publicamos valores fixos de tokens/s ou “usuários simultâneos” sem relatório reproduzível.
O resultado depende de modelo, prompt, saída, batching, GPU, versão e configuração.

Use `scripts/benchmark.sh` e preserve o CSV junto ao manifesto do ambiente.
