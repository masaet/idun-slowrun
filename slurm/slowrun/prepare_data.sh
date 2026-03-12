#!/usr/bin/env bash
# =============================================================================
# slurm/slowrun/prepare_data.sh — Download and tokenise FineWeb 100M tokens
#
# No GPU needed for data preparation.
#
# Submit via submit.sh:
#   bash submit.sh prepare_data
# =============================================================================

#SBATCH --job-name=slowrun-data
#SBATCH --partition=GPUQ
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=logs/slowrun/prepare_data_%j.out
#SBATCH --error=logs/slowrun/prepare_data_%j.err


set -euo pipefail

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
ENV_PATH="${ENV_PATH:-$HOME/conda_envs/slowrun_env}"

module load Miniconda3/24.7.1-0
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_PATH"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DATA_DIR="$HOME/data/slowrun/fineweb_data"
cd "$REPO_DIR/slowrun"

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
echo "==> Starting data preparation at $(date)"
echo "==> Writing data to $DATA_DIR"

echo "==> Starting data preparation at $(date)"
python prepare_data.py --local_dir "$DATA_DIR"
echo "==> Done at $(date)"