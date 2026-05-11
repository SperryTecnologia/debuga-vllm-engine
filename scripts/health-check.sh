#!/usr/bin/env bash
# ============================================================
# health-check.sh — Check vLLM server status and model health
# ============================================================
# Usage:
#   ./scripts/health-check.sh                     # localhost:8000
#   ./scripts/health-check.sh http://gpu:8000      # Remote server
#   ./scripts/health-check.sh http://localhost:8000 --verbose
# ============================================================

set -euo pipefail

BASE_URL="${1:-http://localhost:8000}"
VERBOSE="${2:-}"
TIMEOUT=5
PASSED=0
FAILED=0

# Colors (if terminal supports)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    GREEN='' RED='' YELLOW='' NC=''
fi

pass() { echo -e "   ${GREEN}✓${NC} $1"; ((PASSED++)); }
fail() { echo -e "   ${RED}✗${NC} $1"; ((FAILED++)); }
warn() { echo -e "   ${YELLOW}⚠${NC} $1"; }

echo "============================================================"
echo "debuga-vllm-engine — Health Check"
echo "Target: $BASE_URL"
echo "============================================================"
echo ""

# ---- 1. Server connectivity ----
echo "1. Server Connectivity"
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$BASE_URL/health" 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" ]]; then
    pass "Server responding (HTTP $HTTP_CODE)"
else
    fail "Server not responding (HTTP $HTTP_CODE)"
    echo ""
    echo "   Troubleshooting:"
    echo "   - Check if vLLM is running: docker ps | grep vllm"
    echo "   - Check logs: docker logs debuga-vllm"
    echo "   - Verify port: curl -v $BASE_URL/health"
    exit 1
fi

# ---- 2. Models loaded ----
echo ""
echo "2. Loaded Models"
MODELS_JSON=$(curl -sf --max-time "$TIMEOUT" "$BASE_URL/v1/models" 2>/dev/null || echo "")
if [[ -n "$MODELS_JSON" ]]; then
    MODEL_COUNT=$(echo "$MODELS_JSON" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('data',[])))" 2>/dev/null || echo "0")
    if [[ "$MODEL_COUNT" -gt 0 ]]; then
        pass "$MODEL_COUNT model(s) loaded:"
        echo "$MODELS_JSON" | python3 -c "
import sys, json
for m in json.load(sys.stdin).get('data', []):
    print(f'     - {m[\"id\"]}')
" 2>/dev/null
    else
        fail "No models loaded"
    fi
else
    fail "Could not query /v1/models"
fi

# ---- 3. Inference test ----
echo ""
echo "3. Inference Test"
MODEL_ID=$(echo "$MODELS_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['id'])" 2>/dev/null || echo "")

if [[ -n "$MODEL_ID" ]]; then
    START_NS=$(date +%s%N)
    INFERENCE_JSON=$(curl -sf --max-time 30 "$BASE_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL_ID\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Reply with only: OK\"}],
            \"max_tokens\": 5,
            \"temperature\": 0
        }" 2>/dev/null || echo "")
    END_NS=$(date +%s%N)

    if [[ -n "$INFERENCE_JSON" ]]; then
        LATENCY_MS=$(( (END_NS - START_NS) / 1000000 ))
        CONTENT=$(echo "$INFERENCE_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'][:50])" 2>/dev/null || echo "?")
        TOTAL_TOKENS=$(echo "$INFERENCE_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('usage',{}).get('total_tokens','?'))" 2>/dev/null || echo "?")

        pass "Response: \"$CONTENT\""
        pass "Latency: ${LATENCY_MS}ms"
        pass "Tokens used: $TOTAL_TOKENS"
    else
        fail "Inference request failed"
    fi
else
    warn "Skipped (no model available)"
fi

# ---- 4. Metrics ----
echo ""
echo "4. Metrics"
METRICS=$(curl -sf --max-time "$TIMEOUT" "$BASE_URL/metrics" 2>/dev/null || echo "")
if [[ -n "$METRICS" ]]; then
    pass "Metrics endpoint available"

    if [[ "$VERBOSE" == "--verbose" ]]; then
        GPU_CACHE=$(echo "$METRICS" | grep "^vllm:gpu_cache_usage_perc" | tail -1 | awk '{printf "%.1f%%", $2*100}' 2>/dev/null || echo "N/A")
        RUNNING=$(echo "$METRICS" | grep "^vllm:num_requests_running" | tail -1 | awk '{print int($2)}' 2>/dev/null || echo "N/A")
        WAITING=$(echo "$METRICS" | grep "^vllm:num_requests_waiting" | tail -1 | awk '{print int($2)}' 2>/dev/null || echo "N/A")
        echo "     GPU KV-Cache usage: $GPU_CACHE"
        echo "     Requests running: $RUNNING"
        echo "     Requests waiting: $WAITING"
    fi
else
    warn "Metrics endpoint not available (optional)"
fi

# ---- Summary ----
echo ""
echo "============================================================"
TOTAL=$((PASSED + FAILED))
if [[ "$FAILED" -eq 0 ]]; then
    echo -e "${GREEN}All $TOTAL checks passed.${NC} Server is healthy."
else
    echo -e "${RED}$FAILED of $TOTAL checks failed.${NC} See details above."
fi
echo "============================================================"

exit "$FAILED"
