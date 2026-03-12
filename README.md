# idun - slowrun
Self contained playbook for running [NanoGPT Slowrun](https://github.com/qlabs-eng/slowrun) on IDUN 

 > **What is Slowrun?** Train on 100M tokens from FineWeb, no time limit, lowest validation loss wins. It is the opposite of speedruns like modded-nanogpt — you are optimized for learning, not wall-clock time.

---


## Repo structure

```
idun-slowrun/
├── slowrun/                  ← vendored from qlabs-eng/slowrun (git submodule)
├── slurm/
│   └── slowrun/
│       ├── prepare_data.sh   ← download + tokenise FineWeb (run once)
│       └── train_tiny.sh     ← tiny track (≤15 minutes, 8xH100)
├── logs/                     ← Slurm stdout/stderr (auto-created, git-ignored)
├── setup_env.sh              ← one-time conda environment bootstrap
├── activate_env.sh           ← fast env activation helper
├── submit.sh                 ← job submission entry point
├── .gitignore
└── README.md
```

---



## Prerequisites

- Access to NTNU Idun with a GPU allocation
- A SLURM account on the `GPUQ` partition (e.g. `ie-itk`)
- ~10 GB free storage for the FineWeb data files
- ~5 GB free storage for the conda environment
- A free [Weights & Biases](https://wandb.ai) account for experiment tracking

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/masaet/idun-slowrun.git
cd idun-slowrun
```

---

### 2. Add the slowrun submodule

```bash
git submodule add https://github.com/qlabs-eng/slowrun.git slowrun
git submodule update --init
```

---

### 3. Set your SLURM account

Find your account name:
```bash
sacctmgr show user $USER withassoc format=user,account,partition
```

Add it to your `~/.bashrc` (to avoid having to set the variable for every login):
```bash
echo "export SLURM_ACCOUNT=ie-itk" >> ~/.bashrc
source ~/.bashrc
```

Replace `ie-itk` with your actual account name. (note, account name is not your username, but the name associated with your institute)

---

### 4. Set up the conda environment

Run this once from the repo root:
```bash
bash setup_env.sh
```

This will:
- Load Miniconda3 from Idun's module system
- Create a conda environment at `~/conda_envs/slowrun_env`
- Install PyTorch with the correct CUDA 12.4 build for Idun's H100s
- Install slowrun's dependencies from `slowrun/requirements.txt`

> **Note:** Idun's H100s run CUDA 12.9. PyTorch's newest stable build targets CUDA 12.4, which is fully compatible via NVIDIA's backward compatibility guarantee.

---

### 5. Log in to Weights & Biases

Slowrun uses wandb for experiment tracking. Run this once on Idun:
```bash
source activate_env.sh
wandb login
```

You will be prompted for your API key, which you can find at [wandb.ai/authorize](https://wandb.ai/authorize).

---

### 6. Prepare the data

This only needs to be run **once**. It downloads and tokenises 100M tokens from FineWeb and writes two files to `~/data/slowrun/fineweb_data/`:
- `fineweb_train.pt` — 100M training tokens
- `fineweb_val.pt` — 10M validation tokens

Submit the job:
```bash
bash submit.sh prepare_data
```

Monitor progress:
```bash
squeue -u $USER
tail -f logs/slowrun/prepare_data_"jobnumber".out
```

---

##  Run training

### Tiny track (≤15 minutes — good for testing changes)

```bash
GPU_TYPE=p100 bash submit.sh train_tiny
```

available gpu types: p100, v100, a100, h100

Monitor progress:
```bash
squeue -u $USER
tail -f logs/slowrun/train_tiny_.out
```

---

##  Useful cluster commands

```bash
# Check GPU availability
sinfo -p GPUQ -o "%N %G %t" | grep h100

# Monitor your jobs
squeue -u $USER

# Check why a job is pending
squeue -u $USER -o "%i %j %T %R"

# Check job history
sacct -u $USER --format=JobID,JobName,Partition,State,Elapsed,ExitCode

# Cancel a job
scancel 
```

---

##  Troubleshooting

**`SLURM_ACCOUNT` not set**
```
ERROR: set SLURM_ACCOUNT before submitting
```
Run `export SLURM_ACCOUNT=ie-itk` or add it to your `~/.bashrc`.

**Conda activation fails in job script**
- Verify Miniconda is available: `module avail | grep -i conda`
- Check the environment exists: `ls ~/conda_envs/slowrun_env`

**PyTorch can't see the GPU**
SSH into a compute node and verify:
```bash
srun --partition=GPUQ --gres=gpu:h100:1 --account=$SLURM_ACCOUNT --pty bash
python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
```

**Jobs stuck in PENDING**
- Check reason: `squeue -u $USER -o "%i %j %T %R"`
- `Priority` — other jobs ahead of you, just wait
- `Resources` — no GPUs free right now, try fewer GPUs: `NUM_GPUS=4 bash submit.sh train_tiny`

**NCCL hangs on multi-GPU**
`NCCL_IB_DISABLE=1` is set by default in all job scripts. If issues persist add `NCCL_DEBUG=INFO` to get more diagnostic output.

**Data files not found**
Make sure `prepare_data.sh` completed successfully and the files exist:
```bash
ls ~/data/slowrun/fineweb_data/
```
Should show `fineweb_train.pt` and `fineweb_val.pt`.

---

## Licence

The `slowrun/` subdirectory is MIT licenced per the [upstream repo](https://github.com/qlabs-eng/slowrun).
Everything else in this repo is also MIT licenced.

## Acknowledgements

The structure and approach of this repo is inspired by
[Engaging-NanoGPT](https://github.com/Mabdel-03/Engaging-NanoGPT) by
Mabdel-03, a playbook for running modded-nanogpt on MIT's Engaging cluster.