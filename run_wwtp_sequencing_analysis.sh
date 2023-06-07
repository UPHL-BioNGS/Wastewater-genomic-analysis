#!/bin/bash
# if any errors, then exit
set -e

###########################
# Author: Pooja Gupta

USAGE="
Purpose: Bash script to automate wastewater sequencing analysis. Consists of three individual scripts
1) WWP_seq_initialize_analysis.sh - Set up folder structure for running for sequencing data analysis and cleans up fastq filenames for NCBI submission.
2) run_viralrecon.sh - Run viralrecon bioinformatic pipeline with wastewater sequencing data.
3) run_freyja_vrn_noBoot.sh - Run Freyja with BAM files from viralrecon and generate final output files for Microreact visualization

Usage: run_wwtp_sequencing_analysis.sh <wastewater sequencing run_name>

Last updated on June 05,2023
"
###########################

echo "$USAGE"

run_name=$1

# Script directory for relative paths
script_dir='/Volumes/NGS/Bioinformatics/pooja/ww_analysis_scripts/Wastewater-genomic-analysis'

echo "$(date) : Set up wastewater sequencing analysis"

# Define the path to the log file
log_file1="/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/WWP_seq_new_run_auto.log"

# Create the status file if it does not exist
touch "$log_file1"

$script_dir/WWP_seq_new_run_auto.sh $run_name | tee -a $log_file1

echo "$(date) : Run viralrecon"
log_file2="/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/viralrecon.log"

$script_dir/run_viralrecon.sh $run_name | tee -a $log_file2

#$script_dir/run_viralrecon_primerv5.sh $run_name | tee -a $log_file2

echo "$(date) : Checking if the viralrecon pipeline completed successfully"
if
grep -riwq "Pipeline completed successfully" $log_file2
then
    echo "$(date) : Viralrecon pipeline completed successfully and BAM files are available for Freyja analysis"
else
    echo "$(date) : Oops .. something went wrong and pipeline stopped"
    exit 1
fi

echo "$(date) : Run Freyja analysis"
log_file3=/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/freyja.log

$script_dir/run_freyja_vrn_noBoot_singularity.sh $run_name | tee -a $log_file3


