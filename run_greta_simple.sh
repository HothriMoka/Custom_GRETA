#!/bin/bash

# Simple GRETA Pipeline Runner
# For quick execution without SLURM

echo "=== GRETA Simple Pipeline Runner ==="
echo "Start time: $(date)"

# Set working directory
cd /home/hmoka2/mnt/storage/bioinformatics/users/hmoka/greta

# Setup conda
source ~/miniconda3/etc/profile.d/conda.sh
conda activate base

# Create logs directory
mkdir -p logs

# Function to run a method safely
run_method() {
    local method=$1
    echo "Running $method method..."
    
    if snakemake \
        --use-conda \
        --conda-frontend conda \
        --cores 4 \
        --keep-going \
        generate_grn_${method} \
        --force; then
        echo "✓ $method completed successfully"
        return 0
    else
        echo "✗ $method failed"
        return 1
    fi
}

# Run the pipeline
echo "Starting GRN generation..."

# Run each method
run_method "pando"
run_method "granie"  
run_method "correlation"

# Check results
echo ""
echo "=== Results ==="
if [[ -d "dts/custom_multiome/cases/all/runs" ]]; then
    cd dts/custom_multiome/cases/all/runs
    echo "Generated files:"
    ls -lah *.csv *.tsv
    echo ""
    echo "File statistics:"
    wc -l *.csv *.tsv
else
    echo "No output directory found"
fi

echo ""
echo "=== Pipeline completed at $(date) ===" 