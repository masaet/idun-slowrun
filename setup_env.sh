#!/usr/bin/env bash
# =============================================================================
# setup_env.sh — One-time environment bootstrap for idun-slowrun
# =============================================================================

set -euo pipefail


ENV_PATH="${ENV_PATH:-$HOME/conda_envs/slowrun_env}"

# ---------------------------------------------------------------------------
# 1. Load Miniconda from Idun's module system
# ---------------------------------------------------------------------------
module load Miniconda3/24.7.1-0

# ---------------------------------------------------------------------------
# 2. Create the conda environment (Python 3.11)
# ---------------------------------------------------------------------------
if conda env list | grep -q "$ENV_PATH"; then
    echo "==> Environment already exists at $ENV_PATH. Skipping creation."
else
    echo "==> Creating conda environment at $ENV_PATH ..."
    conda create -y -p "$ENV_PATH" python=3.11
fi

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_PATH"

# ---------------------------------------------------------------------------
# 3. Install PyTorch with the correct CUDA build for Idun's H100s
#    
# Current H100 driver on IDUN: CUDA 12.9
# Current newest stable CUDA release: 12.4
# ---------------------------------------------------------------------------
pip install torch --index-url https://download.pytorch.org/whl/cu124


# ---------------------------------------------------------------------------
# 4. Install slowrun's requirements
#    --extra-index-url ensures torch stays on the cu124 build
#    if any dependency tries to pull it again
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pip install -r "$SCRIPT_DIR/slowrun/requirements.txt" \
    --extra-index-url https://download.pytorch.org/whl/cu124

echo "==> Done! Run 'source activate_env.sh' to activate."