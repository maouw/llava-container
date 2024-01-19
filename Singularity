Bootstrap: docker
From: mambaorg/micromamba:{{ MICROMAMBA_TAG }}

%arguments
	MICROMAMBA_TAG=jammy-cuda-12.3.1
	PYTHON_VERSION=3.11
	LLAVA_ARCHIVE_URL=https://github.com/haotian-liu/LLaVA/archive/refs/tags/v1.1.3.tar.gz
	DASEL_URL=https://github.com/TomWright/dasel/releases/download/v2.5.0/dasel_linux_amd64

%labels
	VERSION 0.0.2

%setup
	[ -n "${APPTAINER_ROOTFS:-}" ] && ./write-apptainer-labels.sh >"${APPTAINER_ROOTFS}/.build_labels"

%files
	llava-run.py /opt/local/bin/llava-run

%post
	set -ex
	export MAMBA_DOCKERFILE_ACTIVATE=1
	export DEBIAN_FRONTEND=noninteractive
	apt-get update -y
	apt-get install -yq --no-install-recommends curl
	apt-get clean -y && rm -rf /var/lib/apt/lists/*

	mkdir -p /opt/setup && cd "$_"
	curl -fL "{{ DASEL_URL }}" -o /opt/setup/dasel && chmod +x /opt/setup/dasel

	curl -fL https://github.com/haotian-liu/LLaVA/archive/refs/tags/v1.1.3.tar.gz -o llava.tar.gz
	mkdir llava
	tar -xzvf llava.tar.gz --directory llava --strip-components 1
	[ -r llava/pyproject.toml ] || {
		"Did not find pyproject.toml in extracted LLaVA source" 2>&echo
		exit 1
	}
	cd llava
	# Add setuptools-scm to pyproject.toml
	/opt/setup/dasel put -f pyproject.toml -t string -v setuptools-scm -s 'build-system.requires.append()'

	mkdir -p /opt/setup && cd "$_"

	micromamba install -y -n base python={{ PYTHON_VERSION }} -c conda-forge pip
	micromamba run -n base python -m pip install --no-cache-dir --upgrade pip
	micromamba run -n base python -m pip install --no-cache-dir .
	micromamba run -n base python -m pip cache purge
	micromamba clean --all --yes

	rm -rf /opt/setup

%environment
	export MAMBA_DOCKERFILE_ACTIVATE=1
	export PATH="/opt/local/bin:$PATH"
	export HUGGINGFACE_HUB_CACHE="${HUGGINGFACE_HUB_CACHE:-}"

%runscript
	# Run the provided command with the micromamba base environment activated:
	eval "$(micromamba shell hook --shell posix)"
	micromamba activate
	exec "$@"

%help
	This container provides a convenient way to run
	[LLaVA](https://github.com/haotian-liu/LLaVA).

	To run LLaVA with the `llava-run` script, use the following command:
		apptainer run --nv --writable-tmpfs llava-container.sif llava-run
	
	You must pass the "--nv" flag to enable GPU support.

	Depending on your intended use, you may also want to pass the "--bind" flag
	to mount a directory from the host system into the container, or add flags
	like "--contain" or "--cleanenv" to change the container runtime behavior.
	
	To specify a directory to use for the HuggingFace model cache, use the
	following command:
		apptainer run --nv --env HUGGINGFACE_HUB_CACHE=/path/to/cache \
			llava-container.sif llava-run
	
	This container includes a script called "llava-run" that runs LLaVA with the
	arguments provided. The following describes the usage of this script:

		llava-run [-h] [--model-path MODEL_PATH] [--model-base MODEL_BASE]
			--image-file IMAGE_FILE --query QUERY [--conv-mode CONV_MODE]
			[--sep SEP] [--temperature TEMPERATURE] [--top_p TOP_P]
			[--num_beams NUM_BEAMS] [--max_new_tokens MAX_NEW_TOKENS]
			[--load-8bit] [--load-4bit] [--device DEVICE]
			[--hf-cache-dir HF_CACHE_DIR]

		options:
			-h, --help				show this help message and exit
			--model-path MODEL_PATH Model path
			--model-base MODEL_BASE Model base
			--image-file IMAGE_FILE Image file
			--query QUERY         Query
			--conv-mode CONV_MODE Conversation mode
			--sep SEP             Separator for image files
			--temperature TEMPERATURE Temperature
			--top_p TOP_P         Top p
			--num_beams NUM_BEAMS Number of beams
			--max_new_tokens MAX_NEW_TOKENS
									Max new tokens
			--load-8bit           Load 8bit model
			--load-4bit           Load 4bit model
			--device DEVICE       cuda or cpu
			--hf-cache-dir HF_CACHE_DIR HuggingFace cache directory
		
		For details on the arguments, see the LLaVA documentation.

