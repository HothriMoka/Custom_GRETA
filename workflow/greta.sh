#!/bin/bash
#####################################################
#SBATCH --output=/dev/null

#SBATCH --job-name=run_greta
#SBATCH --partition=nice
#SBATCH --qos=qos_batch
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=32G
#SBATCH --time=04:00:00    # 0 day, 24 hours, 0 minutes

######################################################

# Set the number of cores (default: 1)
CORES=2

# Activate conda environment (uncomment and update if using conda)
source ~/miniconda3/etc/profile.d/conda.sh
conda activate /home/hmoka2/miniconda3/envs/greta

# load snakemake module 
module load snakemake

# Set pipeline directory (adjust if needed)
PIPELINE_DIR="/home/hmoka2/mnt/storage/bioinformatics/users/hmoka/greta/output"
cd "$PIPELINE_DIR" || { echo "Cannot find workflow directory!"; exit 1; }

# Run snakemake with conda and singularity support (remove --use-singularity if not needed)
snakemake --cores "$CORES" 

# If you want to specify targets explicitly, add them to the command, e.g.:
# snakemake dts/brain/cases/all/runs/dictys.dictys.dictys.dictys.mdl.csv --cores "$CORES" --use-conda --use-singularity
