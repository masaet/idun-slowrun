#!/usr/bin/env bash
# source this file, don't run it directly

ENV_PATH="${ENV_PATH:-$HOME/conda_envs/slowrun_env}"

module load Miniconda3/24.7.1-0
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_PATH"
echo "==> Activated: $ENV_PATH"
