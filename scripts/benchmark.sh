#!/usr/bin/env bash
# ============================================================
# benchmark.sh — Simple benchmark with synthetic prompts
# ============================================================
# Usage:
#   ./scripts/benchmark.sh                         # Default: 10 prompts
#   ./scripts/benchmark.sh http://localhost:8000 20 # Custom URL + count
#
# Measures: latency, throughput, tokens/s
# Uses synthetic DevOps prompts (no real data).
# ============================================================

set -euo pipefail

BASE_URL="${1:-http://localhost:8000}"
NUM_REQUESTS="${2:-10}"
TIMEOUT=60

echo "============================================================"
echo "debuga-vllm-engine — Benchmark"
echo "============================================================"
echo ""
echo "Target:   $BASE_URL"
echo "Requests: $NUM_REQUESTS"
echo ""

# Check server
if ! curl -sf --max-time 5 "$BASE_URL/health" > /dev/null 2>&1; then
    echo "ERROR: Server not responding at $BASE_URL"
    echo "Start vLLM first: ./scripts/start-vllm.sh"
    exit 1
fi

# Get model ID
MODEL_ID=$(curl -sf --max-time 5 "$BASE_URL/v1/models" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['id'])" 2>/dev/null || echo "")

if [[ -z "$MODEL_ID" ]]; then
    echo "ERROR: Could not detect model. Is vLLM running?"
    exit 1
fi

echo "Model: $MODEL_ID"
echo ""

# Synthetic prompts (DevOps/infrastructure themed)
PROMPTS=(
    "Explique como diagnosticar alta latência em um servidor web Nginx."
    "Quais são os passos para configurar fail2ban no Ubuntu 22.04?"
    "Como verificar se um certificado SSL está prestes a expirar usando openssl?"
    "Escreva um script Bash para monitorar uso de disco e alertar acima de 90%."
    "Explique a diferença entre iptables e nftables."
    "Como configurar log rotation para arquivos de log grandes em /var/log?"
    "Quais comandos usar para diagnosticar problemas de DNS em um servidor Linux?"
    "Escreva uma regra de firewall nftables para bloquear brute force em SSH."
    "Como configurar health checks em um Docker Compose com 3 serviços?"
    "Explique como usar tcpdump para capturar tráfego HTTP em uma interface específica."
    "Quais são as melhores práticas para hardening de um servidor PostgreSQL?"
    "Como configurar Prometheus para coletar métricas de um servidor Nginx?"
    "Escreva um script Python para verificar a disponibilidade de múltiplos endpoints."
    "Explique como funciona o load balancing round-robin no Nginx."
    "Como diagnosticar um container Docker que fica em restart loop?"
    "Quais são os passos para migrar de iptables para nftables?"
    "Escreva um Dockerfile multi-stage para uma aplicação Node.js."
    "Como configurar alertas no Grafana baseados em métricas do Prometheus?"
    "Explique como usar strace para diagnosticar um processo que consome muita CPU."
    "Quais são os riscos de segurança de rodar containers Docker como root?"
)

# Results storage
RESULTS_DIR="./benchmark-results"
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$RESULTS_DIR/benchmark_${TIMESTAMP}.csv"

echo "request,prompt_length,latency_ms,total_tokens,prompt_tokens,completion_tokens,tokens_per_second" > "$RESULTS_FILE"

TOTAL_LATENCY=0
TOTAL_TOKENS=0
TOTAL_COMPLETION_TOKENS=0
SUCCESS=0
ERRORS=0

echo "Running $NUM_REQUESTS requests..."
echo ""

for i in $(seq 1 "$NUM_REQUESTS"); do
    # Select prompt (cycle through list)
    IDX=$(( (i - 1) % ${#PROMPTS[@]} ))
    PROMPT="${PROMPTS[$IDX]}"

    # Send request
    START_NS=$(date +%s%N)
    RESPONSE=$(curl -sf --max-time "$TIMEOUT" "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL_ID\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"Você é um especialista em infraestrutura Linux e DevOps. Responda de forma concisa e técnica.\"},
                {\"role\": \"user\", \"content\": $(python3 -c "import json; print(json.dumps('$PROMPT'))" 2>/dev/null || echo "\"$PROMPT\"")}
            ],
            \"max_tokens\": 512,
            \"temperature\": 0.1
        }" 2>/dev/null || echo "")
    END_NS=$(date +%s%N)

    LATENCY_MS=$(( (END_NS - START_NS) / 1000000 ))

    if [[ -n "$RESPONSE" ]] && echo "$RESPONSE" | python3 -c "import sys,json; json.load(sys.stdin)['choices']" &>/dev/null; then
        # Parse response
        USAGE=$(echo "$RESPONSE" | python3 -c "
import sys, json
r = json.load(sys.stdin)
u = r.get('usage', {})
print(f\"{u.get('total_tokens',0)},{u.get('prompt_tokens',0)},{u.get('completion_tokens',0)}\")
" 2>/dev/null || echo "0,0,0")

        IFS=',' read -r TOTAL_T PROMPT_T COMPLETION_T <<< "$USAGE"
        PROMPT_LEN=${#PROMPT}

        # Calculate tokens/s
        if [[ "$LATENCY_MS" -gt 0 && "$COMPLETION_T" -gt 0 ]]; then
            TPS=$(echo "scale=1; $COMPLETION_T * 1000 / $LATENCY_MS" | bc 2>/dev/null || echo "0")
        else
            TPS="0"
        fi

        echo "$i,$PROMPT_LEN,$LATENCY_MS,$TOTAL_T,$PROMPT_T,$COMPLETION_T,$TPS" >> "$RESULTS_FILE"

        TOTAL_LATENCY=$((TOTAL_LATENCY + LATENCY_MS))
        TOTAL_TOKENS=$((TOTAL_TOKENS + TOTAL_T))
        TOTAL_COMPLETION_TOKENS=$((TOTAL_COMPLETION_TOKENS + COMPLETION_T))
        ((SUCCESS++))

        printf "  [%2d/%d] %4dms | %3d tokens | %5.1f tok/s | %s\n" \
            "$i" "$NUM_REQUESTS" "$LATENCY_MS" "$TOTAL_T" "$TPS" "${PROMPT:0:50}..."
    else
        ((ERRORS++))
        printf "  [%2d/%d] ERROR | %s\n" "$i" "$NUM_REQUESTS" "${PROMPT:0:50}..."
    fi
done

# Summary
echo ""
echo "============================================================"
echo "Benchmark Results"
echo "============================================================"
echo ""

if [[ "$SUCCESS" -gt 0 ]]; then
    AVG_LATENCY=$((TOTAL_LATENCY / SUCCESS))
    AVG_TOKENS=$((TOTAL_TOKENS / SUCCESS))
    AVG_COMPLETION=$((TOTAL_COMPLETION_TOKENS / SUCCESS))
    OVERALL_TPS=$(echo "scale=1; $TOTAL_COMPLETION_TOKENS * 1000 / $TOTAL_LATENCY" | bc 2>/dev/null || echo "0")

    echo "  Model:              $MODEL_ID"
    echo "  Requests:           $SUCCESS successful, $ERRORS failed"
    echo "  Avg latency:        ${AVG_LATENCY}ms"
    echo "  Avg tokens/request: $AVG_TOKENS (completion: $AVG_COMPLETION)"
    echo "  Overall throughput: ${OVERALL_TPS} tokens/s"
    echo "  Total tokens:       $TOTAL_TOKENS"
    echo ""
    echo "  Results saved to: $RESULTS_FILE"
else
    echo "  All requests failed. Check server status."
fi

echo ""
echo "============================================================"
