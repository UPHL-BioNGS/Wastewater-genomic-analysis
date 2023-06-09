#!/usr/bin/env python
# coding: utf-8

"""
Last updated: 2023-05-31

This script aggregates lineage data from wastewater sequencing. It takes the latest sequencing run results (new_run_name_dir), 
cleans it up (add collection date, lat-long data) and merges them with previous lineage abundance results,
to output an aggregated output CSV file that can be uploaded into Microreact project.

Usage: freyja_old_new_res_merge.py <new_run_name_dir> <old_res_date>
"""

# Import the required libraries
import argparse
import logging
import pandas as pd
import os
import glob
import sys
from datetime import datetime


# Some custom helper functions

def set_up_logger():
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    handler = logging.FileHandler('app.log')
    handler.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    return logger
logger = set_up_logger()  # Call the logger setup function

def check_abundance_sum(df):
    """
    Check if the abundance values by group (sample_id, collection_date) sum to 1.
    If the sum of abundances is greater than 1, print a message indicating potential duplicates or other inconsistencies.
    
    Parameters:
    df (pd.DataFrame): Input DataFrame containing the lineage data.
    
    Returns:
    None
    """
    # Group by sample_id and collection_date
    grouped = df.groupby(['sample_id', 'collection_date'])

    # Check if the abundances sum to 1 for each group
    for name, group in grouped:
        abundance_sum = group['abundance'].sum()
        if abundance_sum > 1.01:  # Allowing for minor floating-point inaccuracies
            logger.warning(f"Abundance sum for group {name} is greater than 1 (sum = {abundance_sum}). "
               "There might be duplicate entries or other inconsistencies.")


def remove_duplicates(df):
    """
    Remove duplicate entries based on sample_id, collection_date, and lineages columns.

    Parameters:
    df (pd.DataFrame): Input DataFrame containing the lineage data.
    
    Returns:
    pd.DataFrame: DataFrame with duplicate entries removed.
    """
    # Define the columns to be used for identifying duplicates
    duplicate_columns = ['sample_id', 'collection_date', 'lineage']

    # Remove duplicate entries based on the selected columns
    df = df.drop_duplicates(subset=duplicate_columns, keep='first')

    return df

def save_output(df, output_dir, output_file):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    output_path = os.path.join(output_dir, output_file)
    df.to_csv(output_path, index=False)

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('new_run_name_dir', help='Directory of the new run')
    parser.add_argument('old_res_date', help='Date of the old results')
    return parser.parse_args()

def main(config):
    args = parse_arguments()
    run_name = args.new_run_name_dir
    old_res_date = args.old_res_date

    dirpath = os.path.join(config['wastewater_seq_dir'], run_name, 'results')

    # Get the names of the source files
    source_files = glob.glob(os.path.join(dirpath, '*lingrps_final.csv'))

    if not source_files:
            logger.error("No lineage data files found.")
            return

    # Print the names of the source files
    for lineage_file in source_files:
        print(lineage_file)

    # Read in the data from the latest sequencing run
    long_df = pd.read_csv(lineage_file, sep=',')
    long_df[['collection_date', 'msd_shrtnm']] = long_df['sample_id'].str.split('_', n=1, expand=True)
    long_df['collection_date'] = pd.to_datetime(long_df['collection_date'], format='%y%m%d')


    # Read in the latitude and longitude data
    lat_long_df = pd.read_csv(config['lat_long_file'], sep=',')

    # Merge the sequencing run data with the latitude and longitude data
    merged_df = pd.merge(long_df, lat_long_df, on='msd_shrtnm')

    # Extract the date of the old results from the command line arguments
    old_res_date = old_res_date

    # Set the working directory to the directory with the old WW sequencing run results
    old_filepath = os.path.join(config['all_freyja_results_dir'], old_res_date)
    #os.chdir(old_filepath)

    # Get the names of the old result files
    old_files = glob.glob(os.path.join(old_filepath,'*lineage_abundance_cln.csv'))

    # Print the names of the old result files
    for lin_abund in old_files:
        print(lin_abund)

    # Read in the old results
    old_df = pd.read_csv(lin_abund, sep=',')
    old_df['collection_date'] = pd.to_datetime(old_df['collection_date'])

    # Combine the old and new results
    merged_df_old_new = pd.concat([merged_df, old_df], ignore_index=True)
    merged_df_old_new.reset_index(drop=True, inplace=True)
    merged_df_old_new['idx_name'] = merged_df_old_new.index

    # Get the current date
    today = datetime.today()
    date_str = today.strftime('%Y-%m-%d')

    # Set the file path for the new results
    new_filepath = os.path.join(config['all_freyja_results_dir'], date_str)


    # Check if the sum of lineage abundances equals 1 for each sample and date
    check_abundance_sum(merged_df_old_new)
    # Print the total number of rows in the original data
    logger.info(f"Total number of rows in the original data: {merged_df_old_new.shape[0]}")

    # Remove duplicates from the data
    merged_df_old_new_no_dups = remove_duplicates(merged_df_old_new)
    # Print the total number of rows after removing duplicates
    logger.info(f"Total number of rows after removing duplicates: {merged_df_old_new_no_dups.shape[0]}")

    # Calculate and print the number of rows removed
    num_rows_removed = merged_df_old_new.shape[0] - merged_df_old_new_no_dups.shape[0]
    logger.warning(f"Number of rows removed: {num_rows_removed}")

    # Save the processed data to a CSV file with today's date as directory name
    save_output(merged_df_old_new_no_dups,new_filepath,f'{date_str}_WW_feyja_varaints_SC2_lineage_abundance_cln.csv')

    logger.info("Post-processing of freyja results is complete including aggregating results from previous runs. The output file can now be uploaded in Microreact for visualization.")

if __name__ == '__main__':
    config = {
        'wastewater_seq_dir': '/Volumes/IDGenomics_NAS/wastewater_sequencing/',
        'lat_long_file': '/Volumes/IDGenomics_NAS/wastewater_sequencing/wwtp_pscripts/wwp_lat_long.csv',
        'all_freyja_results_dir': '/Volumes/IDGenomics_NAS/wastewater_sequencing/all_freyja_results'
    }
    main(config)