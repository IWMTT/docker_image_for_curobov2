ARG CUROBO_X86_BASE=nvcr.io/nvidia/pytorch:23.08-py3
FROM ${CUROBO_X86_BASE} AS curobo_x86_base

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute \
    PYOPENGL_PLATFORM=egl \
    CUROBO_ALLOW_MOCK_FALLBACK=true

# Based on the official cuRobo x86 docker image recipe:
# https://curobo.org/get_started/5_docker_development.html
# https://github.com/NVlabs/curobo/blob/main/docker/x86.dockerfile
# This prototype keeps only the pieces needed to build cuRobo and run the bridge.
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && apt-get install -y --no-install-recommends \
      pkg-config \
      libglvnd-dev \
      libgl1-mesa-dev \
      libegl1-mesa-dev \
      libgles2-mesa-dev \
      tzdata \
      software-properties-common \
      curl \
      wget \
      build-essential \
      cmake \
      git \
      git-lfs \
      iputils-ping \
      libeigen3-dev \
      libssl-dev \
      python3-pip \
      python3-dev \
      python3-tk \
      && rm -rf /var/lib/apt/lists/* && \
      ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
      echo "America/Los_Angeles" > /etc/timezone && \
      dpkg-reconfigure -f noninteractive tzdata

# Enable EGL path in the same spirit as the official x86 image.
RUN mkdir -p /usr/share/glvnd/egl_vendor.d && \
    echo '{"file_format_version": "1.0.0", "ICD": {"library_path": "libEGL_nvidia.so.0"}}' \
    > /usr/share/glvnd/egl_vendor.d/10_nvidia.json

COPY curobo_bridge/requirements.txt /tmp/bridge-requirements.txt

RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install -r /tmp/bridge-requirements.txt

# Match the official x86 flow by cloning cuRobo inside the image and installing it
# from source with no build isolation. We keep fail-open behavior so the bridge can
# still boot in mock mode if the host lacks the exact GPU/container setup.
RUN mkdir -p /opt/pkgs && git clone https://github.com/NVlabs/curobo.git /opt/pkgs/curobo || true
RUN if [ -d /opt/pkgs/curobo/.git ]; then \
      cd /opt/pkgs/curobo && python3 -m pip install .[dev,usd] --no-build-isolation || true; \
    fi

WORKDIR /app/curobo_bridge

COPY frontend/src/assets/urdf /app/frontend/src/assets/urdf
COPY curobo_bridge /app/curobo_bridge

EXPOSE 9000

CMD ["python3", "planner_server.py"]
