#!/usr/bin/env bash
# ============================================================
# download-model.sh — Download Qwen-Coder models from Hugging Face
# ============================================================
# Usage:
#   ./scripts/download-model.sh              # Show available models
#   ./scripts/download-model.sh 7b-awq       # Download 7B AWQ
#   ./scripts/download-model.sh 14b          # Download 14B FP16
#
# Requires: huggingface-cli (pip install huggingface_hub[cli])
# Optional: HF_TOKEN environment variable for gated models
# ============================================================

set -euo pipefail

MODEL_SIZE="${1:-}"

# Available models
declare -A MODELS=(
    ["1.5b"]="Qwen/Qwen2.5-Coder-1.5B-Instruct"
    ["3b"]="Qwen/Qwen2.5-Coder-3B-Instruct"
    ["7b"]="Qwen/Qwen2.5-Coder-7B-Instruct"
    ["7b-awq"]="Qwen/Qwen2.5-Coder-7B-Instruct-AWQ"
    ["14b"]="Qwen/Qwen2.5-Coder-14B-Instruct"
    ["14b-awq"]="Qwen/Qwen2.5-Coder-14B-Instruct-AWQ"
    ["32b"]="Qwen/Qwen2.5-Coder-32B-Instruct"
    ["32b-awq"]="Qwen/Qwen2.5-Coder-32B-Instruct-AWQ"
)

# Approximate sizes in GB
declare -A SIZES=(
    ["1.5b"]="3" ["3b"]="6" ["7b"]="14" ["7b-awq"]="4"
    ["14b"]="28" ["14b-awq"]="8" ["32b"]="64" ["32b-awq"]="18"
)

# Show usage if no argument
if [[ -z "$MODEL_SIZE" ]] || [[ -z "${MODELS[$MODEL_SIZE]+x}" ]]; then
    echo "============================================================"
    echo "debuga-vllm-engine — Model Downloader"
    echo "============================================================"
    echo ""
    echo "Usage: $0 <model>"
    echo ""
    echo "Available models:"
    echo ""
    printf "  %-10s %-50s %s\n" "Key" "Model ID" "~Size"
    printf "  %-10s %-50s %s\n" "---" "--------" "-----"
    for key in $(echo "${!MODELS[@]}" | tr ' ' '\n' | sort); do
        printf "  %-10s %-50s %s GB\n" "$key" "${MODELS[$key]}" "${SIZES[$key]}"
    done
    echo ""
    echo "Examples:"
    echo "  $0 7b-awq    # Recommended: 7B AWQ (~4 GB, needs 8 GB VRAM)"
    echo "  $0 14b-awq   # Quality: 14B AWQ (~8 GB, needs 16 GB VRAM)"
    echo "  $0 32b-awq   # Maximum: 32B AWQ (~18 GB, needs 2x GPU)"
    exit 1
fi

MODEL_NAME="${MODELS[$MODEL_SIZE]}"
REQUIRED_GB="${SIZES[$MODEL_SIZE]}"

echo "============================================================"
echo "Downloading: $MODEL_NAME"
echo "Estimated size: ~${REQUIRED_GB} GB"
echo "============================================================"

# Check prerequisites
if ! command -v huggingface-cli &> /dev/null; then
    echo ""
    echo "ERROR: huggingface-cli not found."
    echo "Install with: pip install huggingface_hub[cli]"
    exit 1
fi

# Check HF_TOKEN
if [[ -z "${HF_TOKEN:-}" ]]; then
    echo ""
    echo "WARNING: HF_TOKEN not set. Some models may require authentication."
    echo "Set with: export HF_TOKEN=your-token"
    echo "Get token at: https://huggingface.co/settings/tokens"
    echo ""
fi

# Check available disk space
CACHE_DIR="${HF_HOME:-$HOME/.cache/huggingface}"
mkdir -p "$CACHE_DIR"
AVAILABLE_GB=$(df -BG "$CACHE_DIR" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G')

if [[ -n "$AVAILABLE_GB" ]] && (( AVAILABLE_GB < REQUIRED_GB + 5 )); then
    echo ""
    echo "WARNING: Available disk space (~${AVAILABLE_GB} GB) may be insufficient."
    echo "         Model requires ~${REQUIRED_GB} GB plus margin."
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Download
echo ""
echo "Starting download to: $CACHE_DIR"
echo "This may take a while depending on your connection..."
echo ""

huggingface-cli download "$MODEL_NAME" --cache-dir "$CACHE_DIR"

echo ""
echo "============================================================"
echo "Download complete: $MODEL_NAME"
echo "============================================================"
echo ""
echo "Next steps:"
echo ""
echo "  # Start vLLM with this model:"
echo "  MODEL_ID=$MODEL_NAME ./scripts/start-vllm.sh"
echo ""
echo "  # Or update .env:"
echo "  echo 'MODEL_ID=$MODEL_NAME' >> .env"
echo "  docker compose -f docker/docker-compose.yml up -d"
