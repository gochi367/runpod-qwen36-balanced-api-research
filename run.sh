#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "Qwen3.6 Balanced llama.cpp server startup"
echo "Mode: ctx128k + mmproj image support"
echo "============================================================"

MODEL_DIR="${MODEL_DIR:-/tmp/models}"
MODEL_REPO="${MODEL_REPO:-HauhauCS/Qwen3.6-27B-Uncensored-HauhauCS-Balanced}"
MODEL_FILE="${MODEL_FILE:-Qwen3.6-27B-Uncensored-HauhauCS-Balanced-Q5_K_P.gguf}"
MMPROJ_FILE="${MMPROJ_FILE:-mmproj-Qwen3.6-27B-Uncensored-HauhauCS-Balanced-f16.gguf}"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
API_KEY="${API_KEY:-r}"

CTX_SIZE="${CTX_SIZE:-131072}"
N_GPU_LAYERS="${N_GPU_LAYERS:-99}"
BATCH_SIZE="${BATCH_SIZE:-1024}"
UBATCH_SIZE="${UBATCH_SIZE:-512}"
IMAGE_MAX_TOKENS="${IMAGE_MAX_TOKENS:-2048}"

export HF_HUB_ENABLE_HF_TRANSFER="${HF_HUB_ENABLE_HF_TRANSFER:-1}"

mkdir -p "${MODEL_DIR}"

echo "MODEL_DIR=${MODEL_DIR}"
echo "MODEL_REPO=${MODEL_REPO}"
echo "MODEL_FILE=${MODEL_FILE}"
echo "MMPROJ_FILE=${MMPROJ_FILE}"
echo "HOST=${HOST}"
echo "PORT=${PORT}"
echo "CTX_SIZE=${CTX_SIZE}"
echo "N_GPU_LAYERS=${N_GPU_LAYERS}"
echo "BATCH_SIZE=${BATCH_SIZE}"
echo "UBATCH_SIZE=${UBATCH_SIZE}"
echo "IMAGE_MAX_TOKENS=${IMAGE_MAX_TOKENS}"

echo "============================================================"
echo "Finding llama-server..."
echo "============================================================"

LLAMA_SERVER="$(command -v llama-server || true)"

if [ -z "${LLAMA_SERVER}" ]; then
  LLAMA_SERVER="$(find / -name llama-server -type f -executable 2>/dev/null | head -n 1 || true)"
fi

if [ -z "${LLAMA_SERVER}" ]; then
  echo "ERROR: llama-server not found"
  exit 1
fi

echo "llama-server found: ${LLAMA_SERVER}"

echo "============================================================"
echo "Checking Python and huggingface_hub..."
echo "============================================================"

python3 --version

python3 - <<'PY'
import sys
print("Python executable:", sys.executable)
try:
    import huggingface_hub
    print("huggingface_hub:", huggingface_hub.__version__)
except Exception as e:
    print("ERROR: huggingface_hub import failed:", repr(e))
    raise
PY

echo "============================================================"
echo "Downloading main GGUF model..."
echo "============================================================"

python3 - <<PY
from huggingface_hub import hf_hub_download

repo_id = "${MODEL_REPO}"
filename = "${MODEL_FILE}"
local_dir = "${MODEL_DIR}"

print("Downloading:", repo_id, filename)
path = hf_hub_download(
    repo_id=repo_id,
    filename=filename,
    local_dir=local_dir,
    local_dir_use_symlinks=False,
)
print("Downloaded main model to:", path)
PY

echo "============================================================"
echo "Downloading mmproj GGUF..."
echo "============================================================"

python3 - <<PY
from huggingface_hub import hf_hub_download

repo_id = "${MODEL_REPO}"
filename = "${MMPROJ_FILE}"
local_dir = "${MODEL_DIR}"

print("Downloading:", repo_id, filename)
path = hf_hub_download(
    repo_id=repo_id,
    filename=filename,
    local_dir=local_dir,
    local_dir_use_symlinks=False,
)
print("Downloaded mmproj to:", path)
PY

MODEL_PATH="${MODEL_DIR}/${MODEL_FILE}"
MMPROJ_PATH="${MODEL_DIR}/${MMPROJ_FILE}"

echo "============================================================"
echo "Checking downloaded files..."
echo "============================================================"

if [ ! -f "${MODEL_PATH}" ]; then
  echo "ERROR: main model not found: ${MODEL_PATH}"
  ls -lah "${MODEL_DIR}" || true
  exit 1
fi

if [ ! -f "${MMPROJ_PATH}" ]; then
  echo "ERROR: mmproj not found: ${MMPROJ_PATH}"
  ls -lah "${MODEL_DIR}" || true
  exit 1
fi

ls -lah "${MODEL_DIR}"

echo "MODEL_PATH=${MODEL_PATH}"
echo "MMPROJ_PATH=${MMPROJ_PATH}"

echo "============================================================"
echo "GPU check"
echo "============================================================"

if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi || true
else
  echo "nvidia-smi not found"
fi

echo "============================================================"
echo "Starting llama-server with mmproj enabled..."
echo "============================================================"

echo "Command:"
echo "${LLAMA_SERVER} \\"
echo "  -m ${MODEL_PATH} \\"
echo "  --mmproj ${MMPROJ_PATH} \\"
echo "  --host ${HOST} \\"
echo "  --port ${PORT} \\"
echo "  --api-key *** \\"
echo "  -ngl ${N_GPU_LAYERS} \\"
echo "  -c ${CTX_SIZE} \\"
echo "  -b ${BATCH_SIZE} \\"
echo "  -ub ${UBATCH_SIZE} \\"
echo "  --flash-attn on \\"
echo "  --cache-type-k q8_0 \\"
echo "  --cache-type-v q8_0 \\"
echo "  --jinja \\"
echo "  --reasoning off \\"
echo "  --chat-template-kwargs '{\"enable_thinking\":false}' \\"
echo "  --no-mmap \\"
echo "  --image-max-tokens ${IMAGE_MAX_TOKENS}"

exec "${LLAMA_SERVER}" \
  -m "${MODEL_PATH}" \
  --mmproj "${MMPROJ_PATH}" \
  --host "${HOST}" \
  --port "${PORT}" \
  --api-key "${API_KEY}" \
  -ngl "${N_GPU_LAYERS}" \
  -c "${CTX_SIZE}" \
  -b "${BATCH_SIZE}" \
  -ub "${UBATCH_SIZE}" \
  --flash-attn on \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --jinja \
  --reasoning off \
  --chat-template-kwargs '{"enable_thinking":false}' \
  --no-mmap \
  --image-max-tokens "${IMAGE_MAX_TOKENS}"
