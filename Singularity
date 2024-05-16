Bootstrap: docker
From: ubuntu:22.04

%arguments
	LLAVA_URL=https://codeload.github.com/haotian-liu/LLaVA/tar.gz/refs/heads/main
    ENV_NAME=llava
    LLAVA_URL=https://codeload.github.com/haotian-liu/LLaVA/tar.gz/3e337ad269da3245643a2724a1d694b5839c37f9
    USE_CUDA=1
    INSTALL_TRAINING_TOOLS=0
    CUDA_VERSION=12.4.1
    CUDA_ARCHITECTURES=sm_86 sm_89

%files
	../llava-run.py /opt/local/bin/llava-run
    ../environment.yaml environment.yaml
    ../install-llava.sh /usr/local/install-llava.sh
	../runscript.help /.singularity.d/runscript.help
	../hyak-llava-web /opt/local/bin/hyak-llava-web

%post
    export DEBIAN_FRONTEND=noninteractive
    export ENV_NAME="{{ ENV_NAME }}"
    LLAVA_URL="{{ LLAVA_URL }}"
    USE_CUDA="{{ USE_CUDA }}"
    INSTALL_TRAINING_TOOLS="{{ INSTALL_TRAINING_TOOLS }}"
    CUDA_VERSION="{{ CUDA_VERSION }}"
    CUDA_ARCHITECTURES="{{ CUDA_ARCHITECTURES }}"
    export MAMBA_ROOT_PREFIX="/opt/conda"

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

    # Install micromamba:
    curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
    mkdir -p "${MAMBA_ROOT_PREFIX}/conda-meta"
    chmod -R a+rwx "${MAMBA_ROOT_PREFIX}"


    # Install LLaVA dependencies:
    micromamba create -y -n "${ENV_NAME}" -f environment.yml && rm environment.yml

    if [ "${INSTALL_TRAINING_TOOLS:-0}" != 0 ]; then
        export TORCH_CUDA_ARCH_LIST="${CUDA_ARCHITECTURES}"
        micromamba install -y -n "${ENV_NAME}" -e TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST}" nvidia/label/cuda-12.4.1::cuda-toolkit nvidia/label/cuda-12.4.1::cuda-nvcc anaconda::cudnn conda-forge::deepspeed conda-forge::ninja
        micromamba install -y -n "${ENV_NAME}" -e TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST}" -n "${ENV_NAME}" python -m pip install --no-cache-dir flash-attn --no-build-isolation
    fi

    # Download and install LLaVA:
    mkdir -p /opt/setup/llava && cd /opt/setup/llava
    curl -fsSL "${LLAVA_URL}" -o llava.tar.gz
    tar -xzf llava.tar.gz --strip-components=1

    # Update pyproject.toml to include the package data in examples (web server breaks without):
    grep -qF '[tool.setuptools.package-data]' pyproject.toml || printf '[tool.setuptools.package-data]\nllava = ["serve/examples/*.jpg"]' >>pyproject.toml

    # Install LLaVA:
    micromamba run -y -n "${ENV_NAME}" -e TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST}" python -m pip install --no-deps --no-cache-dir --config-settings="--install-data=$PWD/llava" .

	# Clean up:
	micromamba run -n "${ENV_NAME}" python -m pip cache purge
	micromamba clean --all --yes
	rm -rf /opt/setup

%environment
    export ENV_NAME="{{ ENV_NAME }}"
    export MAMBA_ROOT_PREFIX=/opt/conda
	export PATH="/opt/local/bin:${PATH}"

%runscript
	# Run the provided command with the micromamba base environment activated:
	eval "$(micromamba shell hook --shell posix)"
	micromamba activate "${ENV_NAME}"
    if [ -n "${HUGGINGFACE_HUB_CACHE:-}" ]; then
        echo "Using HUGGINGFACE_HUB_CACHE=\"${HUGGINGFACE_HUB_CACHE:-}\"" >&2
    else
        echo "HUGGINGFACE_HUB_CACHE not set!" >&2
    fi
    printf "Started at " && date -Is >&2
	exec "$@"
