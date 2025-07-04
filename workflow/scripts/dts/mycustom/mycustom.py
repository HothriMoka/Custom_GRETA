import pandas as pd
import numpy as np
import mudata as md
import anndata as ad
import scanpy as sc
import argparse
import os

# Init args
parser = argparse.ArgumentParser()
parser.add_argument('-m', '--multiome', required=True)
parser.add_argument('-f', '--frags', required=True)
parser.add_argument('-a', '--annotations', required=True)
parser.add_argument('-o', '--output', required=True)
parser.add_argument('-c', '--csv_out', required=True)
parser.add_argument('-F', '--frags_out', required=True)
args = parser.parse_args()

print(f"Processing multiome file: {args.multiome}")

# Read your h5mu file
mdata = md.read_h5mu(args.multiome)

# ... existing filtering code ...

# Check and add 'celltype' column if missing
if 'celltype' not in mdata.obs.columns:
    print("Warning: 'celltype' column not found. Adding a default 'unknown' column.")
    mdata.obs['celltype'] = 'unknown'

# Create annotation file with proper cell barcode prefix
obs_data = mdata.obs[['batch', 'celltype']].copy()
obs_data.index = ['c0h_' + idx for idx in obs_data.index]
obs_data.to_csv(args.csv_out)

# Update cell barcodes in the data
new_index = ['c0h_' + idx for idx in mdata.obs.index]
mdata.obs.index = new_index
for mod in mdata.mod.keys():
    if hasattr(mdata.mod[mod], 'obs'):
        print(f"Updating modality {mod} index")
        mdata.mod[mod].obs.index = new_index

# Write the processed data
mdata.write(args.output)

# Process fragments file
with open(args.frags, 'r') as fin, open(args.frags_out, 'w') as fout:
    for line in fin:
        parts = line.strip().split('\t')
        if len(parts) >= 4:
            parts[3] = 'c0h_' + parts[3]  # Add prefix to barcode
        fout.write('\t'.join(parts) + '\n')

print(f"Processed data written to {args.output}")
print(f"Final dimensions: {mdata.shape}")

# Print modality dimensions only if they exist
if 'rna' in mdata.mod:
    print(f"RNA dimensions: {mdata.mod['rna'].shape}")
else:
    print("RNA modality not found.")

if 'atac' in mdata.mod:
    print(f"ATAC dimensions: {mdata.mod['atac'].shape}")
else:
    print("ATAC modality not found.")

# Alternatively, print dimensions for all available modalities:
for mod in mdata.mod.keys():
    if hasattr(mdata.mod[mod], 'shape'):
        print(f"{mod} dimensions: {mdata.mod[mod].shape}")
    else:
        print(f"{mod}: no shape attribute found.")

print(f"Annotation written to {args.csv_out}")
print(f"Fragments written to {args.frags_out}")