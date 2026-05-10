FROM ghcr.io/ggml-org/llama.cpp:server-cuda

ENV DEBIAN_FRONTEND=noninteractive

ENV MODEL_DIR=/tmp/models
ENV MODEL_REPO=HauhauCS/Qwen3.6-27B-Uncensored-HauhauCS-Balanced
ENV MODEL_FILE=Qwen3.6-27B-Uncensored-HauhauCS-Balanced-Q5_K_P.gguf
ENV MMPROJ_FILE=mmproj-Qwen3.6-27B-Uncensored-HauhauCS-Balanced-f16.gguf

ENV HOST=0.0.0.0
ENV PORT=8080
ENV API_KEY=r

ENV HF_HUB_ENABLE_HF_TRANSFER=1
ENV PATH="/opt/venv/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    curl \
    aria2 \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv/bin/pip install --no-cache-dir \
      "huggingface_hub[cli]" \
      hf_transfer

COPY run.sh /run.sh

RUN chmod +x /run.sh

EXPOSE 8080

ENTRYPOINT ["/run.sh"]
