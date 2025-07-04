rule mycustom:
    threads: 8
    singularity: 'workflow/envs/gretabench.sif'
    input:
        multiome=config['dts']['mycustom']['url']['multiome'],
        annotations=config['dts']['mycustom']['url']['annotations'],
        frags=config['dts']['mycustom']['url']['frags']
    output:
        annot='dts/mycustom/c0h.csv',
        mdata='dts/mycustom/multiome.h5mu',
        frags_out='dts/mycustom/indv_without_16h_combined.tsv'
    shell:
        """
        python workflow/scripts/dts/mycustom/mycustom.py \
        -m '{input.multiome}' \
        -a '{input.annotations}' \
        -f '{input.frags}' \
        -o '{output.mdata}' \
        -c '{output.annot}' \
        -F '{output.frags_out}'
        """