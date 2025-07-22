import pandas as pd
from io import StringIO
import re
import os
import glob
import json
import sys
#import requests
import datetime
from pango_aliasor.aliasor import Aliasor  # Import the Aliasor class
from utils import (prepLineageDict, expand_data, get_parent_lineage, custom_parent, save_output)


# Define constants for file paths and patterns
WASTEWATER_SEQ_DIR = '/Volumes/NGS_2/wastewater_sequencing/'
DATA_DIR = '/Volumes/NGS/Bioinformatics/ww_analysis_scripts/Wastewater-genomic-analysis/data'

def load_lineage_mapping(filepath):
    with open(filepath, 'r') as file:
        return json.load(file)

def main(run_name):
    dirpath = os.path.join(WASTEWATER_SEQ_DIR, run_name, 'results')
    os.chdir(dirpath)

    source_files = glob.glob(os.path.join(dirpath, '*lineages_aggregate.tsv'))

    if not source_files:
        print("No lineage aggregate files found.")
        return

    for agg_file in source_files:
        print(agg_file)

    # Read the tsv file
    agg_df = pd.read_csv(agg_file, sep='\t', names=['sample_id', 'summarized', 'lineages', 'abundances', 'resid', 'coverage'],skiprows=1)

    # Filter out rows with empty 'lineages' values
    agg_df = agg_df.dropna(subset=['lineages'])

    # Create lineage_dictionary containing lineages and corresponding abundances in 'linDict' column
    processed_data = prepLineageDict(agg_df)

    # Convert the df to long dataframe with lineages, abundances and summarized_lineage columns for each sample
    long_df = expand_data(processed_data)


    # Clean 'sample_id'. Replace hyphens with underscores in sample_id column. This is an optional step.
    long_df['sample_id'] = long_df['sample_id'].apply(lambda x: x.split('_out')[0])
    long_df.loc[:, 'sample_id'] = long_df['sample_id'].apply(lambda x: x.replace("-", "_"))
    
    long_df.index.name = 'idx_name'
    
    # Reset the index to make 'idx_name' a regular column
    long_df.reset_index(inplace=True)

    # Create an Aliasor instance
    aliasor = Aliasor()

    # Create a new column 'compress_lineages' with compressed lineage values using the aliasor package mapping
    long_df['uncompress_lineage'] = long_df['lineage'].apply(lambda x: aliasor.uncompress(x))
    # print(dict_df_matrix_melt_noNA['Uncompress_lineages'].head())  # Print the first few values of the 'Uncompress_lineages' column

    # Create a new column 'Parent_lineage' with compressed parent lineage values using a custom helper function derived from aliasor package
    long_df['parent_lineage'] = long_df['lineage'].apply(lambda x: custom_parent(aliasor, x))

    # print(long_df['Parent_lineage'].tail(20))  # Print the last few values of the 'Parent_lineage' column

    # Exclude some rows from the 'sample_id' column that are not wastewater samples
    for prefix in ['CPC', 'Positive', 'NTC', 'Negative', 'EmptyLane']:
        long_df = long_df[~long_df['sample_id'].str.startswith(prefix)]    

    #Add a Parent_lineage_grp column using custom 'get_parent_lineage' function'

    LINEAGE_MAPPING_FILE_PATH = os.path.join(DATA_DIR, 'lineage_mapping.json')
    
    lineage_mapping = load_lineage_mapping(LINEAGE_MAPPING_FILE_PATH)

    # Get the unique lineages in the 'Parent_lineage' column
    unique_lineages = long_df['uncompress_lineage'].unique()

    # Map the unique Uncompressed lineages to their parent lineage grp using the 'get_parent_lineage()' function
    parent_lineage_grp_mapping = {parent_lineage: get_parent_lineage(parent_lineage, lineage_mapping) for parent_lineage in unique_lineages}

    # Apply the mapping to the 'Parent_lineage' column to create a new 'Parent_lineage_grp' column
    long_df['summarized_lineage'] = long_df['uncompress_lineage'].map(parent_lineage_grp_mapping)

    # Save output #csv format in the run directory

    save_output(long_df,dirpath,f'{run_name}_freyja_lin_dict_long_df_lingrps_final.csv')
    
    # Save output in json format (just in case) because csv modifies the lineage names in weird ways
    #long_df.to_json(f'{run_name}_freyja_lin_dict_long_df_lingrps_final.json', orient='records', lines=True)

    # Count the unique lineages and save to a csv file
    lineage_counts_df = long_df['lineage'].value_counts().reset_index().rename(columns={'index':'lineage', 'lineage':'count'})
    save_output(lineage_counts_df,dirpath,f'{run_name}_lineage_counts.csv')

    #unique_lineage_mapping = long_df[['uncompress_lineage', 'summarized_lineage']].drop_duplicates()
    #save_output(unique_lineage_mapping, dirpath, f'{run_name}_unique_lineage_mapping.csv')


if __name__ == "__main__":
    run_name = sys.argv[1]
    main(run_name)
