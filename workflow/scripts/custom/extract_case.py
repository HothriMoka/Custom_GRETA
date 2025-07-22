#!/usr/bin/env python

import numpy as np
import pandas as pd
import mudata as md
import scanpy as sc
import argparse
import os
import logging

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("extract_case")

# Parse arguments
parser = argparse.ArgumentParser(description='Extract case from multiome data')
parser.add_argument('-i', '--input', required=True, help='Input h5mu file')
parser.add_argument('-c', '--celltypes', required=True, help='Cell types to include, "all" for all')
parser.add_argument('-g', '--n_hvg', type=int, required=True, help='Number of highly variable genes')
parser.add_argument('-r', '--n_hvr', type=int, required=True, help='Number of highly variable regions')
parser.add_argument('-o', '--output', required=True, help='Output h5mu file')
args = parser.parse_args()

logger.info(f"Reading input file: {args.input}")
try:
    mdata = md.read_h5mu(args.input)
    logger.info(f"Successfully read {args.input}")
    logger.info(f"Modalities: {list(mdata.mod.keys())}")
except Exception as e:
    logger.error(f"Error reading input file: {e}")
    raise

# Check modality names and standardize if needed
if 'RNA' in mdata.mod and 'ATAC' in mdata.mod:
    # Rename to lowercase for GRETA compatibility
    mdata.mod['rna'] = mdata.mod.pop('RNA')
    mdata.mod['atac'] = mdata.mod.pop('ATAC')
    logger.info("Renamed modalities to lowercase for GRETA compatibility")

# Process RNA modality
logger.info("Processing RNA modality")
rna = mdata.mod['rna']
logger.info(f"RNA data shape: {rna.shape}")

# Process ATAC modality
logger.info("Processing ATAC modality")
atac = mdata.mod['atac']
logger.info(f"ATAC data shape: {atac.shape}")

# Filter cell types if specified
if args.celltypes != 'all':
    celltypes = args.celltypes.split(';')
    logger.info(f"Filtering cell types: {celltypes}")
    mdata = mdata[np.isin(mdata.obs['celltype'], celltypes)].copy()
    mdata.obs['celltype'] = mdata.obs['celltype'].cat.remove_unused_categories()
    logger.info(f"After filtering: {mdata.shape}")

# Extract
rna = mdata.mod['rna']
atac = mdata.mod['atac']

# Make sure enough features
logger.info("Filtering features with low counts")
if hasattr(rna.X, 'toarray'):
    rna = rna[:, np.sum(rna.X.toarray() != 0, axis=0) > 3].copy()
else:
    rna = rna[:, np.sum(rna.X != 0, axis=0) > 3].copy()
    
if hasattr(atac.X, 'toarray'):
    atac = atac[:, np.sum(atac.X.toarray() != 0, axis=0) > 3].copy()
else:
    atac = atac[:, np.sum(atac.X != 0, axis=0) > 3].copy()

# Normalize
logger.info("Normalizing data")
if 'counts' not in rna.layers:
    rna.layers['counts'] = rna.X.copy()
if 'counts' not in atac.layers:
    atac.layers['counts'] = atac.X.copy()

sc.pp.normalize_total(rna, target_sum=1e4)
sc.pp.log1p(rna)
sc.pp.normalize_total(atac, target_sum=1e4)
sc.pp.log1p(atac)

# HVG
logger.info(f"Finding highly variable features (genes: {args.n_hvg}, regions: {args.n_hvr})")
def filter_hvg(adata, n_hvg):
    if 'batch' in adata.obs:
        sc.pp.highly_variable_genes(adata, batch_key='batch')
    else:
        sc.pp.highly_variable_genes(adata)
        
    hvg = adata.var.sort_values('highly_variable_rank').head(n_hvg).index
    
    # Clean up vars
    if 'highly_variable' in adata.var:
        del adata.var['highly_variable']
    if 'means' in adata.var:
        del adata.var['means']
    if 'dispersions' in adata.var:
        del adata.var['dispersions']
    if 'dispersions_norm' in adata.var:
        del adata.var['dispersions_norm']
    
    return hvg.values.astype('U')

# Add batch key if not present
if 'batch' not in rna.obs:
    logger.info("Adding default batch label")
    rna.obs['batch'] = 'batch1'
    atac.obs['batch'] = 'batch1'
elif 'batch' not in atac.obs:
    logger.info("Copying batch from RNA to ATAC")
    atac.obs['batch'] = rna.obs['batch']
    
hvg = filter_hvg(rna, args.n_hvg)
hvr = filter_hvg(atac, args.n_hvr)

logger.info(f"Selected {len(hvg)} highly variable genes and {len(hvr)} highly variable regions")

rna = rna[:, np.isin(rna.var_names.values.astype('U'), hvg)].copy()
atac = atac[:, np.isin(atac.var_names.values.astype('U'), hvr)].copy()

# Filter cells and intersect
logger.info("Filtering cells and intersecting modalities")
if hasattr(rna.X, 'A'):
    rna = rna[(rna.X.A != 0).sum(1) > 3, :].copy()
else:
    rna = rna[(rna.X != 0).sum(1) > 3, :].copy()
    
if hasattr(atac.X, 'A'):
    atac = atac[(atac.X.A != 0).sum(1) > 3, :].copy()
else:
    atac = atac[(atac.X != 0).sum(1) > 3, :].copy()
    
obs_inter = atac.obs_names.intersection(rna.obs_names)
logger.info(f"Common cells between modalities: {len(obs_inter)}")
rna = rna[obs_inter].copy()
atac = atac[obs_inter].copy()

# Update mdata
mdata = mdata[obs_inter, :].copy()
mdata.mod['rna'] = rna
mdata.mod['atac'] = atac

try:
    # Desparsify if needed
    logger.info("Ensuring dense matrices")
    if hasattr(rna.X, 'toarray'):
        rna.X = rna.X.toarray()
    if hasattr(atac.X, 'toarray'):
        atac.X = atac.X.toarray()

    # Update mdata
    mdata.mod['rna'] = rna
    mdata.mod['atac'] = atac
    mdata.update()
    
    # Save
    logger.info(f"Saving result to {args.output}")
    mdata.write(args.output)
    logger.info("Done!")
except Exception as e:
    logger.error(f"Error in final processing: {e}")
    raise
