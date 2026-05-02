FROM ghcr.io/ggml-org/llama.cpp:server-cuda

ENV MODEL_DIR=/tmp/models
ENV HF_HOME=/tmp/hf_home
ENV HF_HUB_ENABLE_HF_TRANSFER=1
ENV MODEL_REPO=HauhauCS/Qwen3.6-27B-Uncensored-HauhauCS-Balanced
ENV MODEL_FILE=Qwen3.6-27B-Uncensored-HauhauCS-Balanced-Q5_K_P.gguf
ENV MODEL_ALIAS=qwen3.6-27b-balanced
ENV PORT=8000
ENV CTX_SIZE=32768
ENV NGL=99
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    curl \
    aria2 \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/python -m pip install --no-cache-dir -U pip setuptools wheel && \
    /opt/venv/bin/python -m pip install --no-cache-dir -U \
      "huggingface_hub[cli]" \
      hf_xet \
      hf_transfer

COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 8000

ENTRYPOINT ["/run.sh"]
