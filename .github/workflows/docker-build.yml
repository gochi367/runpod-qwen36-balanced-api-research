#!/usr/bin/env bash
set -euo pipefail

: "${API_KEY:=r}"

echo "[1/8] Find llama-server"

SERVER_BIN="/app/llama-server"

if [ ! -x "${SERVER_BIN}" ]; then
  SERVER_BIN="$(command -v llama-server || true)"
fi

if [ -z "${SERVER_BIN}" ] || [ ! -x "${SERVER_BIN}" ]; then
  echo "llama-server not found"
  echo "Searching..."
  find / -maxdepth 5 -type f -name "llama-server" 2>/dev/null || true
  exit 1
fi

echo "Using llama-server: ${SERVER_BIN}"

HELP="$("${SERVER_BIN}" --help 2>&1 || true)"
echo "${HELP}" | head -n 20 || true

has_flag() {
  echo "${HELP}" | grep -q -- "$1"
}

echo "[2/8] Prepare ephemeral model directory"

rm -rf "${MODEL_DIR}"
mkdir -p "${MODEL_DIR}"
mkdir -p "${HF_HOME}"

MODEL_PATH="${MODEL_DIR}/${MODEL_FILE}"

echo "MODEL_DIR=${MODEL_DIR}"
echo "HF_HOME=${HF_HOME}"
echo "MODEL_REPO=${MODEL_REPO}"
echo "MODEL_FILE=${MODEL_FILE}"
echo "MODEL_PATH=${MODEL_PATH}"

echo "[3/8] Download GGUF from Hugging Face"

python - <<'PY'
from huggingface_hub import hf_hub_download
import os

repo_id = os.environ["MODEL_REPO"]
filename = os.environ["MODEL_FILE"]
local_dir = os.environ["MODEL_DIR"]
token = os.environ.get("HF_TOKEN") or None

print(f"repo_id={repo_id}")
print(f"filename={filename}")
print(f"local_dir={local_dir}")
print("Downloading...")

path = hf_hub_download(
    repo_id=repo_id,
    filename=filename,
    local_dir=local_dir,
    token=token
)

print(f"downloaded_path={path}")
PY

echo "[4/8] Check downloaded file"

if [ ! -f "${MODEL_PATH}" ]; then
  echo "Model file not found: ${MODEL_PATH}"
  echo "Listing MODEL_DIR:"
  find "${MODEL_DIR}" -maxdepth 3 -type f -print -exec ls -lh {} \;
  exit 1
fi

FILE_SIZE="$(stat -c%s "${MODEL_PATH}" || echo 0)"
echo "Model file size=${FILE_SIZE} bytes"
ls -lh "${MODEL_PATH}"

if [ "${FILE_SIZE}" -lt 10000000000 ]; then
  echo "Downloaded file is too small. Treat as failure."
  exit 1
fi

echo "[5/8] Optional health check"

curl -s https://huggingface.co >/dev/null || true

echo "[6/8] Build llama-server args"

ARGS=(
  -m "${MODEL_PATH}"
  --host 0.0.0.0
  --port "${PORT}"
  --api-key "${API_KEY}"
  --alias "${MODEL_ALIAS}"
  -c "${CTX_SIZE}"
  -ngl "${NGL}"
)

if has_flag "--jinja"; then
  ARGS+=(--jinja)
fi

if has_flag "--chat-template-kwargs"; then
  ARGS+=(--chat-template-kwargs '{"enable_thinking":false}')
fi

if has_flag "--flash-attn"; then
  ARGS+=(--flash-attn on)
elif has_flag "-fa"; then
  ARGS+=(-fa)
fi

if has_flag "-ctk"; then
  ARGS+=(-ctk q8_0)
elif has_flag "--cache-type-k"; then
  ARGS+=(--cache-type-k q8_0)
fi

if has_flag "-ctv"; then
  ARGS+=(-ctv q8_0)
elif has_flag "--cache-type-v"; then
  ARGS+=(--cache-type-v q8_0)
fi

if has_flag "--cont-batching"; then
  ARGS+=(--cont-batching)
fi

if has_flag "--no-mmproj"; then
  ARGS+=(--no-mmproj)
fi

echo "[7/8] Start llama-server"
echo "Command:"
printf '%q ' "${SERVER_BIN}" "${ARGS[@]}"
echo

echo "[8/8] Exec"
exec "${SERVER_BIN}" "${ARGS[@]}"
