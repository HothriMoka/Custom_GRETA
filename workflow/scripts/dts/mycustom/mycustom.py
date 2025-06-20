import pandas as pd
import numpy as np
import mudata as md
import anndata as ad
import scanpy as sc
import argparse
import os

# Init args
parser = argparse.ArgumentParser()
parser.add_argument('-m','--path_multiome', required=True)
parser.add_argument('-f','--path_frags', required=True) 
parser.add_argument('-a','--path_annot', required=True)
parser.add_argument('-o','--path_output', required=True)
args = vars(parser.parse_args())

path_multiome = args['path_multiome']
path_frags = args['path_frags']
path_annot = args['path_annot']
path_output = args['path_output']

print(f"Processing multiome file: {path_multiome}")

# Read your h5mu file
mdata = md.read_h5mu(path_multiome)

print(f"Original data shape: {mdata.shape}")
print(f"Modalities: {list(mdata.mod.keys())}")

# Check required modalities
if 'rna' not in mdata.mod:
    raise ValueError("RNA modality not found in h5mu file")
if 'atac' not in mdata.mod:
    raise ValueError("ATAC modality not found in h5mu file")

# Get RNA and ATAC data
rna = mdata.mod['rna']
atac = mdata.mod['atac']

print(f"RNA shape: {rna.shape}")
print(f"ATAC shape: {atac.shape}")

# Create basic annotation if not present in the data
if 'celltype' not in mdata.obs.columns:
    # Try to extract cell types from existing annotations
    if 'cell_type' in mdata.obs.columns:
        mdata.obs['celltype'] = mdata.obs['cell_type']
    elif 'cluster' in mdata.obs.columns:
        mdata.obs['celltype'] = mdata.obs['cluster'].astype(str)
    else:
        # Default cell type
        mdata.obs['celltype'] = 'unknown'

if 'batch' not in mdata.obs.columns:
    mdata.obs['batch'] = 'smpl'

# Basic filtering
print("Performing basic filtering...")

# Filter cells with minimum genes/peaks
min_genes = 200
min_peaks = 500

# Count non-zero genes and peaks per cell
n_genes = np.array((rna.X > 0).sum(axis=1)).flatten()
n_peaks = np.array((atac.X > 0).sum(axis=1)).flatten()

print(f"Cells before filtering: {mdata.shape[0]}")
print(f"Mean genes per cell: {n_genes.mean():.1f}")
print(f"Mean peaks per cell: {n_peaks.mean():.1f}")

# Filter cells
cell_filter = (n_genes >= min_genes) & (n_peaks >= min_peaks)
mdata = mdata[cell_filter, :].copy()

print(f"Cells after filtering: {mdata.shape[0]}")

# Filter genes/peaks with minimum cells
min_cells = 3
rna = mdata.mod['rna']
atac = mdata.mod['atac']

gene_filter = np.array((rna.X > 0).sum(axis=0)).flatten() >= min_cells
peak_filter = np.array((atac.X > 0).sum(axis=0)).flatten() >= min_cells

print(f"Genes before filtering: {rna.shape[1]}")
print(f"Peaks before filtering: {atac.shape[1]}")

mdata.mod['rna'] = rna[:, gene_filter].copy()
mdata.mod['atac'] = atac[:, peak_filter].copy()

print(f"Genes after filtering: {mdata.mod['rna'].shape[1]}")
print(f"Peaks after filtering: {mdata.mod['atac'].shape[1]}")

# Create annotation file
obs_data = mdata.obs[['batch', 'celltype']].copy()
obs_data.to_csv(path_annot)

# Ensure cell barcodes have proper format (add smpl_ prefix if not present)
if not mdata.obs.index[0].startswith('smpl_'):
    mdata.obs.index = ['smpl_' + idx for idx in mdata.obs.index]
    mdata.mod['rna'].obs.index = mdata.obs.index
    mdata.mod['atac'].obs.index = mdata.obs.index

# Write the processed data
mdata.write(path_output)

print(f"Processed data written to {path_output}")
print(f"Final dimensions: {mdata.shape}")
print(f"RNA dimensions: {mdata.mod['rna'].shape}")
print(f"ATAC dimensions: {mdata.mod['atac'].shape}")
print(f"Annotation written to {path_annot}")
