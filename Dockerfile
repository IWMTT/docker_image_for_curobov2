ARG BASE_IMAGE=runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG CUROBO_REF=v0.8.0
ARG CUROBO_EXTRA=cu12-torch

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    UV_SYSTEM_PYTHON=1 \
    MPLBACKEND=Agg \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    CUROBO_USE_LRU_CACHE=1 \
    CUROBO_HOME=/opt/curobo \
    NOTEBOOK_DIR=/workspace \
    JUPYTER_HOST=0.0.0.0 \
    JUPYTER_PORT=8888 \
    VISER_PORT=8080 \
    JUPYTER_TOKEN=

SHELL ["/bin/bash", "-lc"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    ffmpeg \
    git \
    git-lfs \
    libegl1 \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    libsm6 \
    libxext6 \
    libxrender1 \
    pkg-config \
    tini \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip uv && \
    python3 -m pip install --upgrade "jupyterlab>=4" "notebook>=7"

RUN git lfs install --system && \
    git clone --branch ${CUROBO_REF} --depth 1 https://github.com/NVlabs/curobo.git ${CUROBO_HOME} && \
    cd ${CUROBO_HOME} && \
    git lfs pull && \
    uv pip install --system .[${CUROBO_EXTRA}] && \
    python3 -c "import curobo; print(curobo.__version__)"

RUN mkdir -p /workspace /opt/container

COPY docker/start-services.sh /opt/container/start-services.sh

RUN chmod +x /opt/container/start-services.sh

WORKDIR /workspace

EXPOSE 8080 8888

ENTRYPOINT ["/usr/bin/tini", "--", "/opt/container/start-services.sh"]
