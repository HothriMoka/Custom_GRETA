rule mycustom:
    threads: 8
    singularity: 'workflow/envs/gretabench.sif'
    input:
        multiome=config['dts']['mycustom']['url']['multiome'],
        annotations=config['dts']['mycustom']['url']['annotations'],
        frags=config['dts']['mycustom']['url']['frags']
    output:
        annot='dts/mycustom/c0h.csv',
        mdata='dts/mycustom/multiome_fixed.h5mu',
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

rule extract_case_mycustom:
    threads: 8
    singularity: 'workflow/envs/gretabench.sif'
    input:
        mdata=rules.mycustom.output.mdata
    output:
        mdata='dts/mycustom/cases/all/mdata.h5mu'
    params:
        celltypes=lambda w: config['dts']['mycustom']['cases']['all']['celltypes'],
        n_sample=lambda w: config['dts']['mycustom']['cases']['all'].get('n_sample', '0'),
        seed=lambda w: config['dts']['mycustom']['cases']['all'].get('seed', '0'),
        n_hvg=lambda w: config['dts']['mycustom']['cases']['all']['n_hvg'],
        n_hvr=lambda w: config['dts']['mycustom']['cases']['all']['n_hvr'],
        root=lambda w: config['dts']['mycustom']['cases']['all'].get('root', 'None')
    shell:
        """
        python workflow/scripts/dts/extract_case.py \
        -i '{input.mdata}' \
        -c '{params.celltypes}' \
        -s '{params.n_sample}' \
        -d '{params.seed}' \
        -g '{params.n_hvg}' \
        -r '{params.n_hvr}' \
        -t '{params.root}' \
        -o '{output.mdata}'
        """