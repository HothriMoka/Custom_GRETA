from snakemake.utils import min_version
min_version('7.29.0')
import sys
import os
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("custom_pipeline")

configfile: 'config/custom_config.yaml'

logger.info("Loading config file and setting up workflow")

# Only define the necessary functions and datasets
def restart_mem(wildcards, attempt):
    mem = (2 ** (4 + attempt)) * 1000
    return mem

# Define map_rules function to handle rule dependencies
def map_rules(step, dat_or_method):
    """Map between different pipeline stages and methods"""
    if step == 'annotate':
        if dat_or_method == 'custom_multiome':
            return 'dts/custom_multiome/mdata_annotated.h5mu'
        else:
            return f'dts/{dat_or_method}/mdata_annotated.h5mu'
    elif step == 'pre':
        return f'dts/custom_multiome/cases/all/runs/{dat_or_method}.pre.h5mu'
    elif step == 'p2g':
        return f'dts/custom_multiome/cases/all/runs/{dat_or_method}.p2g.csv'
    elif step == 'tfb':
        return f'dts/custom_multiome/cases/all/runs/{dat_or_method}.tfb.csv'
    elif step == 'mdl':
        return f'dts/custom_multiome/cases/all/runs/{dat_or_method}.mdl.csv'
    else:
        raise ValueError(f"Unknown step: {step}")

# Get basic config values
try:
    orgms = [k for k in config['dbs'] if k != 'ont']
    logger.info(f"Found organisms: {orgms}")
except Exception as e:
    logger.error(f"Error processing organisms: {e}")
    orgms = ['hg38']

try:
    mthds = [m for m in list(config['methods'].keys())]
    logger.info(f"Found methods: {mthds}")
except Exception as e:
    logger.error(f"Error processing methods: {e}")
    mthds = []

try:
    baselines = config['baselines']
    logger.info(f"Found baselines: {baselines}")
except Exception as e:
    logger.error(f"Error processing baselines: {e}")
    baselines = []

logger.info("Including necessary rule files")

# Include dataset and GRN generation rules
include: 'rules/dts/custom_multiome.smk'

logger.info("Setting up target rules")

# Define a comprehensive all rule that includes GRN generation
rule all:
    input:
        'dts/custom_multiome/mdata_annotated.h5mu',
        'dts/custom_multiome/cases/all/mdata.h5mu',
        # Add GRN targets for multiple methods
        'dts/custom_multiome/cases/all/runs/correlation.correlation.correlation.correlation.grn.csv',
        'dts/custom_multiome/cases/all/runs/correlation.correlation.correlation.correlation.rnk.tsv',
        'dts/custom_multiome/cases/all/runs/pando.pando.pando.pando.grn.csv',
        'dts/custom_multiome/cases/all/runs/pando.pando.pando.pando.rnk.tsv',
        'dts/custom_multiome/cases/all/runs/granie.granie.granie.granie.grn.csv',
        'dts/custom_multiome/cases/all/runs/granie.granie.granie.granie.rnk.tsv',
        # Add intermediate files
        'dts/custom_multiome/cases/all/runs/correlation.p2g.csv',
        'dts/custom_multiome/cases/all/runs/pando.p2g.csv',
        'dts/custom_multiome/cases/all/runs/granie.p2g.csv'

rule copy_annotated_to_case:
    input:
        src='dts/custom_multiome/mdata_annotated.h5mu'
    output:
        dest='dts/custom_multiome/cases/all/mdata.h5mu'
    shell:
        """
        mkdir -p dts/custom_multiome/cases/all
        cp {input.src} {output.dest}
        """
