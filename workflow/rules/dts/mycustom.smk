rule mycustom:
    threads: 8
    singularity: 'workflow/envs/gretabench.sif'
    input:
        multiome=config['dts']['mycustom']['url']['multiome'],
        frags=config['dts']['mycustom']['url']['frags']
    output:
        annot='dts/mycustom/c0h.csv',
        mdata='dts/mycustom/annotated.h5mu',
        frags='dts/mycustom/c0h.frags.tsv.gz'
    shell:
        """
        python workflow/scripts/dts/mycustom/mycustom.py \
        -m '{input.multiome}' \
        -f '{input.frags}' \
        -a '{output.annot}' \
        -o '{output.mdata}'
        
        # Format fragments file for GRETA
        awk 'BEGIN{{OFS="\t"}} {{print $1, $2, $3, "c0h_"$4, $5}}' {input.frags} | \
        bgzip > {output.frags}
        tabix -p bed {output.frags}
        """
