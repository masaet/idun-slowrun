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
echo "==> Submitting $SCRIPT with account=$SLURM_ACCOUNT"

sbatch \
    --account="$SLURM_ACCOUNT" \
    ${NUM_GPUS:+--gres=gpu:h100:$NUM_GPUS} \
    "$SCRIPT"