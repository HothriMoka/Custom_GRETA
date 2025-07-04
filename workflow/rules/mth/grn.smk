localrules: grn_run


rule grn_run:
    threads: 1
    input:
        mdl=lambda w: map_rules('mdl', w.dat, w.mdl),
        pid='dbs/hg38/gen/pid/uniprot.csv'
    output:
        out='dts/{dat}/cases/{case}/runs/{pre}.{p2g}.{tfb}.{mdl}.grn.csv'
    resources:
        mem_mb=4000,
        runtime=60
    shell:
        """
        python workflow/scripts/mth/grn_run.py \
        -i '{input.mdl}' \
        -p '{input.pid}' \
        -o '{output.out}'
        """


rule mdl_collectri:
    threads: 1
    singularity: 'workflow/envs/gretabench.sif'
    input:
        mdata=rules.extract_case.output.mdata,
        grn=rules.gst_collectri.output,
        proms=rules.cre_promoters.output,
    output:
        out='dts/{dat}/cases/{case}/runs/collectri.collectri.collectri.collectri.mdl.csv'
    resources:
        mem_mb=restart_mem,
        runtime=config['max_mins_per_step'],
    shell:
        """
        python workflow/scripts/mth/prc_prior_grn.py \
        -g {input.grn} \
        -d {input.mdata} \
        -p {input.proms} \
        -o {output.out}
        """


rule mdl_dorothea:
    threads: 1
    singularity: 'workflow/envs/gretabench.sif'
    input:
        mdata=rules.extract_case.output.mdata,
        grn=rules.gst_dorothea.output,
        proms=rules.cre_promoters.output,
    output:
        out='dts/{dat}/cases/{case}/runs/dorothea.dorothea.dorothea.dorothea.mdl.csv'
    resources:
        mem_mb=restart_mem,
        runtime=config['max_mins_per_step'],
    shell:
        """
        python workflow/scripts/mth/prc_prior_grn.py \
        -g {input.grn} \
        -d {input.mdata} \
        -p {input.proms} \
        -o {output.out}
        """
