#!/usr/bin/env bash
# ============================================================
# start-vllm.sh — Start vLLM server with .env configuration
# ============================================================
# Usage:
#   ./scripts/start-vllm.sh                    # Use .env defaults
#   MODEL_ID=Qwen/... ./scripts/start-vllm.sh  # Override model
#
# Requires: Python 3.10+, vLLM installed, NVIDIA GPU
# For Docker usage, prefer docker-compose instead.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if present
ENV_FILE="$PROJECT_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
    echo "Loading configuration from: $ENV_FILE"
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
else
    echo "WARNING: No .env file found at $ENV_FILE"
    echo "Using defaults. Copy .env.example to .env to configure."
    echo ""
fi

# Defaults
MODEL_ID="${MODEL_ID:-Qwen/Qwen2.5-Coder-7B-Instruct-AWQ}"
QUANTIZATION="${QUANTIZATION:-awq}"
VLLM_PORT="${VLLM_PORT:-8000}"
TENSOR_PARALLEL_SIZE="${TENSOR_PARALLEL_SIZE:-1}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-8192}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.9}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-32}"
ENABLE_PREFIX_CACHING="${ENABLE_PREFIX_CACHING:-true}"
VLLM_API_KEY="${VLLM_API_KEY:-}"

# Validate prerequisites
echo "============================================================"
echo "debuga-vllm-engine — Starting vLLM"
echo "============================================================"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 not found. Install Python 3.10+."
    exit 1
fi

# Check vLLM
if ! python3 -c "import vllm" 2>/dev/null; then
    echo "ERROR: vLLM not installed."
    echo "Install with: pip install vllm"
    exit 1
fi

# Check NVIDIA GPU
if ! command -v nvidia-smi &> /dev/null; then
    echo "ERROR: nvidia-smi not found. NVIDIA driver required."
    exit 1
fi

echo ""
echo "Configuration:"
echo "  Model:          $MODEL_ID"
echo "  Quantization:   $QUANTIZATION"
echo "  Port:           $VLLM_PORT"
echo "  Tensor Parallel: $TENSOR_PARALLEL_SIZE"
echo "  Max Context:    $MAX_MODEL_LEN tokens"
echo "  GPU Utilization: $GPU_MEMORY_UTILIZATION"
echo "  Max Sequences:  $MAX_NUM_SEQS"
echo "  Prefix Caching: $ENABLE_PREFIX_CACHING"
echo ""

# Show GPU info
echo "GPU Information:"
nvidia-smi --query-gpu=name,memory.total,memory.free,driver_version \
    --format=csv,noheader 2>/dev/null | while IFS=',' read -r name total free driver; do
    echo "  $name | Total:$total | Free:$free | Driver:$driver"
done
echo ""

# Build command
CMD=(
    python3 -m vllm.entrypoints.openai.api_server
    --model "$MODEL_ID"
    --port "$VLLM_PORT"
    --tensor-parallel-size "$TENSOR_PARALLEL_SIZE"
    --max-model-len "$MAX_MODEL_LEN"
    --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION"
    --max-num-seqs "$MAX_NUM_SEQS"
)

# Add quantization if specified
if [[ -n "$QUANTIZATION" && "$QUANTIZATION" != "null" && "$QUANTIZATION" != "none" ]]; then
    CMD+=(--quantization "$QUANTIZATION")
fi

# Add prefix caching
if [[ "$ENABLE_PREFIX_CACHING" == "true" ]]; then
    CMD+=(--enable-prefix-caching)
fi

# Add API key if set
if [[ -n "$VLLM_API_KEY" ]]; then
    CMD+=(--api-key "$VLLM_API_KEY")
fi

echo "Starting vLLM..."
echo "Command: ${CMD[*]}"
echo ""
echo "API will be available at: http://localhost:$VLLM_PORT"
echo "Health check: http://localhost:$VLLM_PORT/health"
echo "Models list: http://localhost:$VLLM_PORT/v1/models"
echo ""
echo "Press Ctrl+C to stop."
echo "============================================================"
echo ""

# Start vLLM
exec "${CMD[@]}"
