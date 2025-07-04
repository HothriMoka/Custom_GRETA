import sys
import argparse
import snapatac2 as snap
import muon as mu
import numpy as np

def parse_arguments():
    parser = argparse.ArgumentParser(description='Extract case from multiome data.')
    parser.add_argument('-i', '--input', type=str, required=True, help='Input MuData file')
    parser.add_argument('-c', '--case', type=str, required=True, help='Case name')
    parser.add_argument('-s', '--seed', type=int, default=0, help='Random seed')
    parser.add_argument('-d', '--downsample', type=int, default=0, help='Downsample to N cells')
    parser.add_argument('-g', '--genes', type=int, default=16384, help='Number of genes to keep')
    parser.add_argument('-r', '--regions', type=int, default=65536, help='Number of regions to keep')
    parser.add_argument('-t', '--time', type=str, default='None', help='Time point to extract')
    parser.add_argument('-o', '--output', type=str, required=True, help='Output MuData file')
    return parser.parse_args()

def main():
    args = parse_arguments()
    
    print(f"Loading {args.input}")
    mdata = mu.read(args.input)
    
    print(f"Original dimensions: {mdata.n_obs} cells")
    
    # Extract specific time point if requested
    if args.time != 'None':
        time_col = 'time'  # Adjust if your time column has a different name
        if time_col in mdata.obs.columns:
            print(f"Extracting time point {args.time}")
            mdata = mdata[mdata.obs[time_col] == args.time, :].copy()
            print(f"After time extraction: {mdata.n_obs} cells")
        else:
            print(f"Warning: Time column '{time_col}' not found in data")
    
    # Downsample if requested
    if args.downsample > 0 and mdata.n_obs > args.downsample:
        np.random.seed(args.seed)
        print(f"Downsampling to {args.downsample} cells")
        indices = np.random.choice(mdata.n_obs, size=args.downsample, replace=False)
        mdata = mdata[indices, :].copy()
        print(f"After downsampling: {mdata.n_obs} cells")
    
    # Check if 'rna' modality exists
    if 'rna' in mdata.mod:
        rna = mdata.mod['rna']
        print(f"RNA modality found: {rna.n_obs} cells, {rna.n_vars} genes")
        
        # Feature selection for RNA
        if args.genes > 0 and args.genes < rna.n_vars:
            print(f"Selecting top {args.genes} variable genes")
            mu.pp.calculate_qc_metrics(rna)
            # Implement your gene selection logic here
            # For example:
            # sc.pp.highly_variable_genes(rna, n_top_genes=args.genes)
            # rna = rna[:, rna.var.highly_variable].copy()
    else:
        print("RNA modality not found. Skipping RNA processing.")
    
    # Check if 'atac' modality exists
    if 'atac' in mdata.mod:
        atac = mdata.mod['atac']
        print(f"ATAC modality found: {atac.n_obs} cells, {atac.n_vars} regions")
        
        # Feature selection for ATAC
        if args.regions > 0 and args.regions < atac.n_vars:
            print(f"Selecting top {args.regions} variable regions")
            # Implement your region selection logic here
    else:
        print("ATAC modality not found. Skipping ATAC processing.")
    
    # Save the output
    print(f"Saving to {args.output}")
    mdata.write(args.output)
    print(f"Final dimensions: {mdata.n_obs} cells")

if __name__ == "__main__":
    main()