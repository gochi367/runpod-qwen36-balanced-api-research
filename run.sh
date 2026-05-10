#!/usr/bin/env bash
set -euo pipefail

MODEL_DIR="${MODEL_DIR:-/tmp/models}"
MODEL_REPO="${MODEL_REPO:-HauhauCS/Qwen3.6-27B-Uncensored-HauhauCS-Balanced}"
MODEL_FILE="${MODEL_FILE:-Qwen3.6-27B-Uncensored-HauhauCS-Balanced-Q5_K_P.gguf}"
MMPROJ_FILE="${MMPROJ_FILE:-mmproj-Qwen3.6-27B-Uncensored-HauhauCS-Balanced-f16.gguf}"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
API_KEY="${API_KEY:-r}"

mkdir -p "${MODEL_DIR}"

echo "Finding llama-server..."
LLAMA_SERVER="$(command -v llama-server || true)"

if [ -z "${LLAMA_SERVER}" ]; then
  LLAMA_SERVER="$(find / -name llama-server -type f -executable 2>/dev/null | head -n 1 || true)"
fi

if [ -z "${LLAMA_SERVER}" ]; then
  echo "ERROR: llama-server not found"
  exit 1
fi

echo "llama-server: ${LLAMA_SERVER}"

echo "Downloading main GGUF..."
python3 - <<PY
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id="${MODEL_REPO}",
    filename="${MODEL_FILE}",
    local_dir="${MODEL_DIR}",
    local_dir_use_symlinks=False,
)
PY

echo "Downloading mmproj GGUF..."
python3 - <<PY
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id="${MODEL_REPO}",
    filename="${MMPROJ_FILE}",
    local_dir="${MODEL_DIR}",
    local_dir_use_symlinks=False,
)
PY

MODEL_PATH="${MODEL_DIR}/${MODEL_FILE}"
MMPROJ_PATH="${MODEL_DIR}/${MMPROJ_FILE}"

echo "MODEL_PATH=${MODEL_PATH}"
echo "MMPROJ_PATH=${MMPROJ_PATH}"

exec "${LLAMA_SERVER}" \
  -m "${MODEL_PATH}" \
  --mmproj "${MMPROJ_PATH}" \
  --host "${HOST}" \
  --port "${PORT}" \
  --api-key "${API_KEY}" \
  -ngl 99 \
  -c 131072 \
  -b 1024 \
  -ub 512 \
  --flash-attn on \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --jinja \
  --reasoning off \
  --chat-template-kwargs '{"enable_thinking":false}' \
  --no-mmap \
  --image-max-tokens 2048
