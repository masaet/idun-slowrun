#!/usr/bin/env bash
# =============================================================================
# submit.sh — Submission helper for idun-slowrun
#
# Handles SLURM_ACCOUNT and passes NUM_GPUS through to the job script.
#
# Usage:
#   export SLURM_ACCOUNT=ie-itk   # set once in your ~/.bashrc
#   bash submit.sh <job>
#
# Available jobs:
#   prepare_data
#   train_tiny
#
# Examples:
#   bash submit.sh prepare_data
#   bash submit.sh train_tiny
#   NUM_GPUS=4 bash submit.sh train_tiny
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Validate SLURM_ACCOUNT
# ---------------------------------------------------------------------------
: "${SLURM_ACCOUNT:?ERROR: set SLURM_ACCOUNT before submitting, e.g. export SLURM_ACCOUNT=ie-itk}"

# ---------------------------------------------------------------------------
# Validate job argument
# ---------------------------------------------------------------------------
JOB="${1:-}"
if [ -z "$JOB" ]; then
    echo "ERROR: no job specified."
    echo "Usage: bash submit.sh <job>"
    echo "Available jobs: prepare_data, train_tiny"
    exit 1
fi

SCRIPT="slurm/slowrun/${JOB}.sh"
if [ ! -f "$SCRIPT" ]; then
    echo "ERROR: script not found: $SCRIPT"
    echo "Available jobs: prepare_data, train_tiny"
    exit 1
fi

# ---------------------------------------------------------------------------
# Create logs directory if it doesn't exist
# ---------------------------------------------------------------------------
mkdir -p logs/slowrun

# ---------------------------------------------------------------------------
# Submit
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# GPU type — default to h100, override with GPU_TYPE=p100 etc.
# ---------------------------------------------------------------------------
GPU_TYPE="${GPU_TYPE:-h100}"
NUM_GPUS="${NUM_GPUS:-}"       #Set to empty to prevent unbound variable error

case "$GPU_TYPE" in
    h100|h200)
        CPUS_PER_GPU=8
        MEM_PER_GPU=32
        DEFAULT_GPUS=8
        ;;
    a100)
        CPUS_PER_GPU=8
        MEM_PER_GPU=32
        DEFAULT_GPUS=4
        ;;
    v100)
        CPUS_PER_GPU=6
        MEM_PER_GPU=24
        DEFAULT_GPUS=2
        ;;
    p100)
        CPUS_PER_GPU=4
        MEM_PER_GPU=16
        DEFAULT_GPUS=2
        ;;
    *)
        CPUS_PER_GPU=4
        MEM_PER_GPU=16
        DEFAULT_GPUS=1
        ;;
esac

TOTAL_CPUS=$(( CPUS_PER_GPU * NUM_GPUS ))
TOTAL_MEM=$(( MEM_PER_GPU * NUM_GPUS ))G
NUM_GPUS="${NUM_GPUS:-$DEFAULT_GPUS}"

TIME="${TIME:-00:15:00}"

echo "==> Submitting $SCRIPT with account=$SLURM_ACCOUNT"

sbatch \
    --account="$SLURM_ACCOUNT" \
    --gres=gpu:${GPU_TYPE}:${NUM_GPUS} \
    --cpus-per-task=${TOTAL_CPUS} \
    --mem=${TOTAL_MEM} \
    --time=${TIME} \
    "$SCRIPT"
