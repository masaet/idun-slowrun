#!/usr/bin/env bash
# =============================================================================
# slurm/slowrun/train_tiny.sh — Tiny track (≤15 minutes, single 8xH100 node)
#
# Good for quickly testing changes before a full limited run.
#
# Submit via submit.sh:
#   bash submit.sh train_tiny
#
# Override GPU count at submission time:
#   NUM_GPUS=4 bash submit.sh train_tiny
# =============================================================================

#SBATCH --job-name=slowrun-tiny
#SBATCH --partition=GPUQ
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:h100:8
#SBATCH --cpus-per-task=64
#SBATCH --mem=256G
#SBATCH --time=00:15:00
#SBATCH --output=logs/slowrun/train_tiny_%j.out
#SBATCH --error=logs/slowrun/train_tiny_%j.err

set -euo pipefail

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
NUM_GPUS="${NUM_GPUS:-8}"
ENV_PATH="${ENV_PATH:-$HOME/conda_envs/slowrun_env}"

module load Miniconda3/24.7.1-0
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_PATH"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_DIR="$HOME/idun-slowrun"
DATA_DIR="$HOME/data/slowrun/fineweb_data"

cd "$REPO_DIR/slowrun/tiny"

# ---------------------------------------------------------------------------
# NCCL
# ---------------------------------------------------------------------------
export NCCL_IB_DISABLE=1
export NCCL_DEBUG=WARN

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
echo "==> Starting tiny track training with $NUM_GPUS GPUs at $(date)"
echo "==> Node: $(hostname)"
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

torchrun \
    --standalone \
    --nproc_per_node="$NUM_GPUS" \
    train.py \
    --input_bin "$DATA_DIR/fineweb_train.pt" \
    --input_val_bin "$DATA_DIR/fineweb_val.pt"

echo "==> Done at $(date)"