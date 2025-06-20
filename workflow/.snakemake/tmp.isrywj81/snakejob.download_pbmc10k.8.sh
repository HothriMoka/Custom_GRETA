#!/bin/bash
# properties = {"type": "single", "rule": "download_pbmc10k", "local": false, "input": [], "output": ["dts/pbmc10k/smpl.frags.tsv.gz", "dts/pbmc10k/smpl.frags.tsv.gz.tbi"], "wildcards": {}, "params": {"matrix": "https://cf.10xgenomics.com/samples/cell-arc/1.0.0/pbmc_granulocyte_sorted_10k/pbmc_granulocyte_sorted_10k_filtered_feature_bc_matrix.h5", "atac_frags": "https://cf.10xgenomics.com/samples/cell-arc/1.0.0/pbmc_granulocyte_sorted_10k/pbmc_granulocyte_sorted_10k_atac_fragments.tsv.gz"}, "log": [], "threads": 1, "resources": {"mem_mb": 1000, "mem_mib": 954, "disk_mb": 1000, "disk_mib": 954, "tmpdir": "<TBD>"}, "jobid": 8, "cluster": {}}

# exit on first error
set -o errexit

echo JOB_ID=$SLURM_JOB_ID

cd /home/hmoka2/mnt/storage/bioinformatics/users/hmoka/greta/workflow && /opt/software/apps/spack/linux-rocky8-icelake/python/3.10.12-qdw4iom/bin/python3.10 -m snakemake --snakefile '/home/hmoka2/mnt/storage/bioinformatics/users/hmoka/greta/workflow/Snakefile' --target-jobs 'download_pbmc10k:' --allowed-rules 'download_pbmc10k' --cores 'all' --attempt 1 --force-use-threads  --resources 'mem_mb=1000' 'mem_mib=954' 'disk_mb=1000' 'disk_mib=954' --wait-for-files '/home/hmoka2/mnt/storage/bioinformatics/users/hmoka/greta/workflow/.snakemake/tmp.isrywj81' --force --keep-target-files --keep-remote --max-inventory-time 0 --nocolor --notemp --no-hooks --nolock --ignore-incomplete --rerun-triggers 'params' 'input' 'software-env' 'code' 'mtime' --skip-script-cleanup  --conda-frontend 'mamba' --wrapper-prefix 'https://github.com/snakemake/snakemake-wrappers/raw/' --printshellcmds  --latency-wait 60 --scheduler 'greedy' --scheduler-solver-path '/opt/software/apps/spack/linux-rocky8-icelake/python/3.10.12-qdw4iom/bin' --default-resources 'mem_mb=max(2*input.size_mb, 1000)' 'disk_mb=max(2*input.size_mb, 1000)' 'tmpdir=system_tmpdir' --mode 2 && exit 0 || exit 1


