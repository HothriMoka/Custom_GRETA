#!/bin/bash
#SBATCH --job-name=greta_multiome
#SBATCH --output=logs/greta_multiome_%j.out
#SBATCH --error=logs/greta_multiome_%j.err
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=compute

# GRETA Pipeline Execution Script
# Run custom multiome GRN inference pipeline

echo "=== GRETA Pipeline Job Started ==="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURMD_NODENAME"
echo "Start time: $(date)"
echo "Working directory: $(pwd)"

# Create logs directory if it doesn't exist
mkdir -p logs

# Set up error handling
set -e
trap 'echo "Error occurred at line $LINENO. Exit code: $?" >&2' ERR

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if files exist
check_input_files() {
    log "Checking input files..."
    
    MDATA_FILE="/home/hmoka2/mnt/storage/bioinformatics/users/hmoka/input/multiome_fixed.h5mu"
    ANNOT_FILE="/home/hmoka2/mnt/storage/bioinformatics/users/hmoka/input/multiome_annotations.csv"
    
    if [[ ! -f "$MDATA_FILE" ]]; then
        log "ERROR: Multiome data file not found: $MDATA_FILE"
        exit 1
    fi
    
    if [[ ! -f "$ANNOT_FILE" ]]; then
        log "ERROR: Annotation file not found: $ANNOT_FILE"
        exit 1
    fi
    
    log "✓ Input files validated"
    log "  - Multiome data: $MDATA_FILE ($(du -h "$MDATA_FILE" | cut -f1))"
    log "  - Annotations: $ANNOT_FILE ($(du -h "$ANNOT_FILE" | cut -f1))"
}

# Function to setup conda environment
setup_conda() {
    log "Setting up conda environment..."
    
    # Initialize conda
    if [[ -f ~/miniconda3/etc/profile.d/conda.sh ]]; then
        source ~/miniconda3/etc/profile.d/conda.sh
        log "✓ Conda initialized from ~/miniconda3"
    elif [[ -f /opt/miniconda3/etc/profile.d/conda.sh ]]; then
        source /opt/miniconda3/etc/profile.d/conda.sh
        log "✓ Conda initialized from /opt/miniconda3"
    else
        log "ERROR: Could not find conda installation"
        exit 1
    fi
    
    # Activate base environment
    conda activate base
    log "✓ Base conda environment activated"
    
    # Check snakemake availability
    if ! command -v snakemake &> /dev/null; then
        log "ERROR: Snakemake not found in base environment"
        log "Installing snakemake..."
        conda install -y -c bioconda snakemake
    fi
    
    log "✓ Snakemake available: $(snakemake --version)"
}

# Function to run individual GRN methods
run_grn_method() {
    local method=$1
    log "Running GRN method: $method"
    
    # Run with timeout and retry logic
    local max_attempts=2
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log "  Attempt $attempt/$max_attempts for $method"
        
        if timeout 3600 snakemake \
            --use-conda \
            --conda-frontend conda \
            --cores 4 \
            --keep-going \
            --rerun-incomplete \
            generate_grn_${method} \
            --force; then
            
            log "✓ $method completed successfully"
            return 0
        else
            log "✗ $method failed on attempt $attempt"
            ((attempt++))
            
            if [[ $attempt -le $max_attempts ]]; then
                log "  Retrying in 30 seconds..."
                sleep 30
            fi
        fi
    done
    
    log "✗ $method failed after $max_attempts attempts"
    return 1
}

# Function to verify outputs
verify_outputs() {
    log "Verifying pipeline outputs..."
    
    local output_dir="dts/custom_multiome/cases/all/runs"
    local methods=("correlation" "pando" "granie")
    local extensions=("grn.csv" "rnk.tsv" "p2g.csv" "tfb.csv")
    
    local total_files=0
    local found_files=0
    
    for method in "${methods[@]}"; do
        for ext in "${extensions[@]}"; do
            local filename
            if [[ $ext == "p2g.csv" ]]; then
                filename="${method}.${ext}"
            elif [[ $ext == "tfb.csv" ]]; then
                filename="${method}.${method}.${ext}"
            else
                filename="${method}.${method}.${method}.${method}.${ext}"
            fi
            
            local filepath="${output_dir}/${filename}"
            ((total_files++))
            
            if [[ -f "$filepath" ]] && [[ -s "$filepath" ]]; then
                local size=$(du -h "$filepath" | cut -f1)
                local lines=$(wc -l < "$filepath")
                log "  ✓ $filename ($size, $lines lines)"
                ((found_files++))
            else
                log "  ✗ Missing or empty: $filename"
            fi
        done
    done
    
    log "Output verification: $found_files/$total_files files found"
    
    if [[ $found_files -eq $total_files ]]; then
        log "✓ All expected output files generated successfully"
        return 0
    else
        log "✗ Some output files missing or empty"
        return 1
    fi
}

# Function to generate summary report
generate_report() {
    log "Generating pipeline summary report..."
    
    local report_file="logs/greta_pipeline_report_${SLURM_JOB_ID}.txt"
    
    {
        echo "=== GRETA Pipeline Execution Report ==="
        echo "Job ID: $SLURM_JOB_ID"
        echo "Execution time: $(date)"
        echo "Node: $SLURMD_NODENAME"
        echo ""
        
        echo "=== Input Files ==="
        echo "Multiome data: /home/hmoka2/mnt/storage/bioinformatics/users/hmoka/input/multiome_fixed.h5mu"
        echo "Annotations: /home/hmoka2/mnt/storage/bioinformatics/users/hmoka/input/multiome_annotations.csv"
        echo ""
        
        echo "=== Output Files ==="
        if [[ -d "dts/custom_multiome/cases/all/runs" ]]; then
            cd dts/custom_multiome/cases/all/runs
            ls -lah *.csv *.tsv 2>/dev/null || echo "No output files found"
            echo ""
            echo "=== File Statistics ==="
            wc -l *.csv *.tsv 2>/dev/null || echo "No files to count"
        else
            echo "Output directory not found"
        fi
        
    } > "$report_file"
    
    log "✓ Report generated: $report_file"
}

# Main execution function
main() {
    log "Starting GRETA pipeline execution"
    
    # Step 1: Validate inputs
    check_input_files
    
    # Step 2: Setup environment
    setup_conda
    
    # Step 3: Clean previous runs (optional)
    log "Cleaning previous incomplete runs..."
    rm -rf .snakemake/incomplete/* 2>/dev/null || true
    
    # Step 4: Run data preparation steps
    log "Running data preparation..."
    snakemake \
        --use-conda \
        --conda-frontend conda \
        --cores 4 \
        --keep-going \
        dts/custom_multiome/mdata_annotated.h5mu \
        dts/custom_multiome/cases/all/mdata.h5mu \
        --force
    
    # Step 5: Run GRN inference methods
    local methods=("pando" "granie" "correlation")
    local successful_methods=()
    local failed_methods=()
    
    for method in "${methods[@]}"; do
        if run_grn_method "$method"; then
            successful_methods+=("$method")
        else
            failed_methods+=("$method")
        fi
    done
    
    # Step 6: Report results
    log "=== Pipeline Execution Summary ==="
    log "Successful methods: ${successful_methods[*]:-none}"
    log "Failed methods: ${failed_methods[*]:-none}"
    
    # Step 7: Verify outputs
    if verify_outputs; then
        log "✓ Pipeline completed successfully"
        exit_code=0
    else
        log "✗ Pipeline completed with issues"
        exit_code=1
    fi
    
    # Step 8: Generate report
    generate_report
    
    log "=== GRETA Pipeline Job Completed ==="
    log "End time: $(date)"
    
    return $exit_code
}

# Execute main function
main "$@"

# Exit with appropriate code
exit $? 