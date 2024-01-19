# llava-container

This container provides a convenient way to run [LLaVA](https://github.com/haotian-liu/LLaVA).

To run LLaVA using [Apptainer](https://apptainer.org/docs/user/main/index.html), run the following command:

```bash
apptainer run --nv --writable-tmpfs oras://ghcr.io/uw-psych/llava-container:0.0.2 llava-run
```

You **must** pass the `--nv` flag to enable GPU support.

Depending on your intended use, you may also want to pass the `--bind` flag to mount a directory from the host system into the container or add flags like `--contain` or `--cleanenv` to change the container runtime behavior.

To specify a directory to use for the HuggingFace model cache, you can pass the `--env` flag to set the `HUGGINGFACE_HUB_CACHE` environment variable. For example:

```bash
apptainer run --nv --writable-tmpfs --env HUGGINGFACE_HUB_CACHE=/path/to/cache oras://ghcr.io/uw-psych/llava-container:0.0.2
```

The `llava-run.py` script is a modification of `LLaVA/lava/eval/run_llava.py` that adds support for loading 4- and 8-bit models as found in `LaVA/llava/serve/cli.py`.

If you want to use a different command, you can pass it after the image name:

```bash
apptainer run --nv --writable-tmpfs --env HUGGINGFACE_HUB_CACHE=/path/to/cache oras://ghcr.io/uw-psych/llava-container:0.0.2 python -m llava.serve.cli
```

## Running LLaVA on Klone

Here is a complete example of running LLaVA on the [Klone](https://uw-psych.github.io/compute_docs/docs/compute/slurm.html) SLURM cluster:

```bash
# Request a GPU node with 8 CPUs, 2 GPUs, 64GB of RAM, and 1 hour of runtime:
# (Note: you may need to change the account and partition)
salloc --account escience --partition gpu-a40 --mem 64G -c 8 --time 1:00:00 --gpus 2
```

Then, **when logged in to the compute node**:

```bash
# Check if Apptainer is available; load the default Lmod if it's not:
command -v apptainer 2>&1 >/dev/null || module load apptainer 

# Set Apptainer cache directory unless it's already set:
export APPTAINER_CACHEDIR="${APPTAINER_CACHEDIR:-/gscratch/scrubbed/${USER}/apptainer-cache}"
# ^^ This is needed to avoid running out of space in your home directory! ^^

# Note: Storage under /gscratch/scrubbed may be slow. If model loading is slow,
# you can try using a different directory for the HuggingFace cache,
# e.g. /gscratch/your-group/${USER}/hf-cache

# ALWAYS be sure your APPTAINER_CACHEDIR and HUGGINGFACE_HUB_CACHE are set;
# otherwise, you may run out of space in your home directory!

# Run LLaVA:
apptainer run \
    --nv \
    --writable-tmpfs \
    --bind /gscratch \
    --env HUGGINGFACE_HUB_CACHE=/gscratch/scrubbed/${USER}/hf-cache \
    oras://ghcr.io/uw-psych/llava-container:0.0.2 \
    llava-run \
    --model-path liuhaotian/llava-v1.5-7b \
    --image-file "https://llava-vl.github.io/static/images/view.jpg" \
    --query "What's going on here?"
# --nv: enable GPU support
# --writable-tmpfs: ensure /tmp is writable
# --bind /gscratch: ensure /gscratch is accessible
# --env: set the HuggingFace cache directory
#   oras://ghcr.io/uw-psych/llava-container:0.0.2: The container
#   llava-run: the command to run in the container
# --model-path: the name of the model to use
# --image-file: the URL of the image to use
# --query: what to ask the model


# When you're done, exit the compute node:
exit
```

This is what the sample image looks like:

![Sample image](https://llava-vl.github.io/static/images/view.jpg)

If it all works, you should see output like this:

> The image features a pier extending out into a large body of water, possibly a lake or a river. The pier is made of wood and has a few benches placed on it, providing a place for people to sit and enjoy the view. The water appears calm and serene, making it an ideal spot for relaxation and contemplation.
>
> In the background, there are mountains visible, adding to the picturesque scenery. The pier is situated in front of a forest, creating a peaceful and natural atmosphere.

### `llava-run` usage

The following describes the usage of `llava-run`:

```plain
    llava-run [-h] [--model-path MODEL_PATH] [--model-base MODEL_BASE]
        --image-file IMAGE_FILE --query QUERY [--conv-mode CONV_MODE]
        [--sep SEP] [--temperature TEMPERATURE] [--top_p TOP_P]
        [--num_beams NUM_BEAMS] [--max_new_tokens MAX_NEW_TOKENS]
        [--load-8bit] [--load-4bit] [--device DEVICE]
        [--hf-cache-dir HF_CACHE_DIR]

    options:
        -h, --help                         show this help message and exit
        --model-path MODEL_PATH            Model path
        --model-base MODEL_BASE            Model base
        --image-file IMAGE_FILE            Image file
        --query QUERY                      Query
        --conv-mode CONV_MODE              Conversation mode
        --sep SEP                          Separator for image files
        --temperature TEMPERATURE          Temperature
        --top_p TOP_P                      Top p
        --num_beams NUM_BEAMS              Number of beams
        --max_new_tokens MAX_NEW_TOKENS    Max new tokens
        --load-8bit                        Load 8bit model
        --load-4bit                        Load 4bit model
        --device DEVICE                    cuda or cpu
        --hf-cache-dir HF_CACHE_DIR        HuggingFace cache directory 
```

For details on the arguments, see the LLaVA documentation.

### Setting up the web interface

```bash
# Go to the directory where you want to store the container:
cd /gscratch/scrubbed/${USER}

# Apptainer setup:
export APPTAINER_BIND=/gscratch APPTAINER_WRITABLE_TMPFS=1 APPTAINER_NV=1

# Set up the HuggingFace cache:
export HUGGINGFACE_HUB_CACHE="$PWD/hf-cache"

# Get a free port number:
grport="$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1])')"

# Launch the container:
apptainer run oras://ghcr.io/uw-psych/llava-container:0.0.2 python -m llava.serve.controller --host 0.0.0.0 --port "$grport &

```