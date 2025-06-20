#!/bin/bash
# properties = {"type": "single", "rule": "prcannot_pbmc10k", "local": false, "input": [], "output": ["dts/pbmc10k/annot.csv"], "wildcards": {}, "params": {}, "log": [], "threads": 1, "resources": {"mem_mb": 1000, "mem_mib": 954, "disk_mb": 1000, "disk_mib": 954, "tmpdir": "<TBD>"}, "jobid": 6, "cluster": {}}

# exit on first error
set -o errexit

echo JOB_ID=$SLURM_JOB_ID

cd /home/hmoka2/mnt/storage/bioinformatics/users/hmoka/greta/workflow && /opt/software/apps/spack/linux-rocky8-icelake/python/3.10.12-qdw4iom/bin/python3.10 -m snakemake --snakefile '/home/hmoka2/mnt/storage/bioinformatics/users/hmoka/greta/workflow/Snakefile' --target-jobs 'prcannot_pbmc10k:' --allowed-rules 'prcannot_pbmc10k' --cores 'all' --attempt 1 --force-use-threads  --resources 'mem_mb=1000' 'mem_mib=954' 'disk_mb=1000' 'disk_mib=954' --wait-for-files '/home/hmoka2/mnt/storage/bioinformatics/users/hmoka/greta/workflow/.snakemake/tmp.fk2bflq1' --force --keep-target-files --keep-remote --max-inventory-time 0 --nocolor --notemp --no-hooks --nolock --ignore-incomplete --rerun-triggers 'mtime' 'params' 'input' 'software-env' 'code' --skip-script-cleanup  --conda-frontend 'mamba' --wrapper-prefix 'https://github.com/snakemake/snakemake-wrappers/raw/' --printshellcmds  --latency-wait 60 --scheduler 'greedy' --scheduler-solver-path '/opt/software/apps/spack/linux-rocky8-icelake/python/3.10.12-qdw4iom/bin' --default-resources 'mem_mb=max(2*input.size_mb, 1000)' 'disk_mb=max(2*input.size_mb, 1000)' 'tmpdir=system_tmpdir' --mode 2 && exit 0 || exit 1


