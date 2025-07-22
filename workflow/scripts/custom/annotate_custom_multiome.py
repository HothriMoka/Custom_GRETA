#!/usr/bin/env python

import numpy as np
import pandas as pd
import mudata as md
import argparse
import os
import scanpy as sc
import snapatac2 as snap

# Parse arguments
parser = argparse.ArgumentParser(description='Annotate custom multiome data')
parser.add_argument('-i', '--input', required=True, help='Input h5mu file')
parser.add_argument('-a', '--annot', required=True, help='Annotation CSV file')
parser.add_argument('-o', '--output', required=True, help='Output h5mu file')
args = parser.parse_args()

# Read data
print("Reading multiome data...")
mdata = md.read_h5mu(args.input)

# Read annotations
print("Reading annotations...")
annot = pd.read_csv(args.annot, index_col=0)

# Check modality names and standardize if needed
print(f"Original modality names: {list(mdata.mod.keys())}")
if 'RNA' in mdata.mod and 'ATAC' in mdata.mod:
    # Rename to lowercase for GRETA compatibility
    mdata.mod['rna'] = mdata.mod.pop('RNA')
    mdata.mod['atac'] = mdata.mod.pop('ATAC')
    print("Renamed modalities to lowercase for GRETA compatibility")

# Process RNA modality
rna = mdata.mod['rna']
print(f"RNA data shape: {rna.shape}")

# Process ATAC modality
atac = mdata.mod['atac']
print(f"ATAC data shape: {atac.shape}")

# Add annotations to observations
print("Adding annotations to observations...")
for col in annot.columns:
    if col in ['donor', 'batch', 'Majority_Celltype']:
        print(f"Adding column: {col}")
        # Ensure all cell barcodes from annotations exist in the data
        common_barcodes = mdata.obs_names.intersection(annot.index)
        mdata.obs[col] = pd.Series('Unknown', index=mdata.obs_names)
        mdata.obs.loc[common_barcodes, col] = annot.loc[common_barcodes, col]
        
        if col == 'Majority_Celltype':
            mdata.obs['celltype'] = mdata.obs[col]

# Make sure 'batch' column exists
if 'batch' not in mdata.obs.columns:
    print("Adding 'batch' column with default value 'Batch1'")
    mdata.obs['batch'] = 'Batch1'

# Make sure modality matrices are dense
for mod in ['rna', 'atac']:
    if hasattr(mdata.mod[mod].X, 'toarray'):
        print(f"Converting {mod} matrix to dense format")
        mdata.mod[mod].X = mdata.mod[mod].X.toarray()

# Create counts layer if it doesn't exist
for mod in ['rna', 'atac']:
    if 'counts' not in mdata.mod[mod].layers:
        print(f"Creating 'counts' layer for {mod}")
        mdata.mod[mod].layers['counts'] = mdata.mod[mod].X.copy()

# Ensure cell type is a categorical
if 'celltype' in mdata.obs:
    mdata.obs['celltype'] = mdata.obs['celltype'].astype('category')

# Update data
print("Updating data...")
mdata.update()

# Save
print(f"Saving annotated data to {args.output}")
mdata.write(args.output)
print("Done!") 