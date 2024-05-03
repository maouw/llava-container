#!/usr/bin/env bash
set -ex -o pipefail
	export DEBIAN_FRONTEND=noninteractive
    PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
    export ENV_NAME="${EMV_NAME:-base}"
    LLAVA_URL="${LLAVA_URL:-https://codeload.github.com/haotian-liu/LLaVA/tar.gz/refs/heads/main}"

	apt-get update -yq
	apt-get install -y --no-install-recommends \
		bzip2 \
		ca-certificates \
		curl \
		git \
        less \
        nano
    apt-get clean --yes --quiet
    rm -rf /var/lib/apt /var/lib/dpkg /var/lib/cache /var/lib/log
	
	export LANG=C.UTF-8 LC_ALL=C.UTF-8
	export MAMBA_ROOT_PREFIX="/opt/conda"
	
	# Install micromamba:
    curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
	mkdir -p "${MAMBA_ROOT_PREFIX}/conda-meta"
	chmod -R a+rwx "${MAMBA_ROOT_PREFIX}"
	
	# Set up the micromamba base environment, using requests to download LLaVA:
	micromamba create -y -n "${ENV_NAME}" -c conda-forge python="${PYTHON_VERSION}" pip	

    # Install yq
    micromamba install -y -n "${ENV_NAME}" -c conda-forge yq

	# Download and install LLaVA:
	mkdir -p /opt/setup/llava && cd /opt/setup/llava
    curl -fsSL "{{ LLAVA_URL }}" -o llava.tar.gz
	tar -xzf llava.tar.gz --strip-components=1
	
    yq -oy '.project.dependencies' pyproject.toml | sed -E 's/^\s*-\s*//' > requirements.txt
	# Update pyproject.toml to include the package data in examples (web server breaks without):
    grep -qF '[tool.setuptools.package-data]' pyproject.toml || printf '[tool.setuptools.package-data]\nllava = ["serve/examples/*.jpg"]' >>pyproject.toml
	
	# Install LLaVA dependencies:
    # OR
    CONDA_OVERRIDE_CUDA="11.2"  micromamba run -n "${ENV_NAME}" mamba install "tensorflow==2.7.0=cuda112*" -c conda-forge
	micromamba run -n base python -m pip install --no-cache-dir -r /opt/setup/requirements.txt
	
	# Install LLaVA:
	micromamba run -n base python -m pip install --no-cache-dir --config-settings="--install-data=$PWD/llava" .
	
    # Install additions:
	# Install training dependencies:
	micromamba run -e TORCH_CUDA_ARCH_LIST="{{ CUDA_ARCHITECTURES }}" -n base python -m pip install ".[train]"
	micromamba run -e TORCH_CUDA_ARCH_LIST="{{ CUDA_ARCHITECTURES }}" -n base python -m pip install flash-attn --no-build-isolation
	
	# Clean up:
	micromamba clean --all --yes
	rm -rf /opt/setup