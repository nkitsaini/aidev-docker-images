# Vast.ai development image

This image keeps the exact third-party dependencies from the checked-in lock
warm in uv's cache, while using Vast.ai's stock Python 3.14 base. The project lock
already includes CUDA-enabled PyTorch and its CUDA 13 runtime wheels, so a CUDA
devel/PyTorch base would store a second copy of much of the same GPU stack.

## Refresh the dependency snapshot

Set `PROJECT_DIR` to the source project directory before refreshing the
snapshot.

```bash
PROJECT_DIR=/path/to/project ./sync_requirements.sh
```

The script exports with `--locked`, so it fails if `uv.lock` is out of date.
Commit the resulting `pylock.toml`; changing it invalidates only the warm-cache
layer.

## Build

```bash
docker build -f Dockerfile.vastai-pytorch -t vastai-pytorch .
```

At runtime, activate or use the project normally:

```bash
cd /workspace/your-project
uv sync --frozen --extra cu130
```

The stock base contains the same Vast boot hooks used by the much larger
`*-auto` images. This image runs those hooks from both supported startup paths:
the project-owned entrypoint wrapper and `/etc/rc.local`, which Vast's generated
`/.launch` script invokes when it replaces the image entrypoint. This restores
the complete upstream initialization sequence—including environment export,
SSH-key repair, shell setup, provisioning, and supervised services—without
restoring the duplicate CUDA/PyTorch layers. The build also removes any
base-layer `authorized_keys` file so Vast can create it afresh when provisioning
the instance.

`UV_LINK_MODE=copy` is intentional because Vast may mount `/workspace` on a
filesystem different from the image's `/.uv/cache`. The copy consumes space in
the project virtual environment, but avoids cross-filesystem link failures.

## Measured footprint

The previous published image has 11.27 GB of compressed registry layers and
occupies roughly 20 GB unpacked. A local build of this Dockerfile measured:

- 8.79 GB for the unpacked image
- 4.8 GB for the warm uv cache inside that image
- 4.9 GB additional workspace usage after creating the project environment
- 4.65 seconds to install all 74 applicable packages entirely offline

Expect roughly 14 GB of local disk use after the first `uv sync`, before source
code, datasets, or models. A 20-25 GB Vast disk allocation is therefore a
practical minimum even though the image itself no longer needs 20 GB. Registry
compression should put the pull near 4-5 GB; confirm the exact figure after the
first optimized image is pushed.

If the project later compiles CUDA extensions or requires `nvcc`, switch the
base to Vast's matching `cuda-13.x-mini-py314` or CUDA-devel image. The current
project dependencies use the CUDA runtime bundled by PyTorch and do not require
the toolkit.
