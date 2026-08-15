#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="${PROJECT_DIR:-${BUILDING_LLM_DIR:-${repo_dir}/../building_llm}}"

# --locked catches a stale uv.lock instead of silently changing it while an
# image dependency snapshot is being generated.
uv export \
    --directory "${project_dir}" \
    --locked \
    --extra cu130 \
    --no-hashes \
    --no-emit-workspace \
    --format pylock.toml \
    --output-file "${repo_dir}/pylock.toml"

# Keep the generated header independent of this checkout's absolute path.
sed -i '2c#    uv export --locked --extra cu130 --no-hashes --no-emit-workspace --format pylock.toml' \
    "${repo_dir}/pylock.toml"
