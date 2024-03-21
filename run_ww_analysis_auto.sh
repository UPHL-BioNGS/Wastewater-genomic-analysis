#!/bin/bash
# if any errors, then exit
set -e

###########################
# Author: Pooja Gupta

USAGE="
Purpose: Bash script to automate wastewater sequencing analysis. Consists of three individual scripts
1) setup_ww_seq.sh - Set up folder structure for running for sequencing data analysis and cleans up fastq filenames for NCBI submission.
2) run_viralrecon.sh - Run viralrecon bioinformatic pipeline with wastewater sequencing data.
3) run_freyja.sh - Run Freyja with BAM files from viralrecon and generate final output files for Microreact visualization

Usage: run_ww_analysis_auto.sh <wastewater sequencing run_name>

Last updated on Mar 20,2024
"
###########################

echo "$USAGE"

run_name=$1
resume_option=$2

# Script directory for relative paths
script_dir='/Volumes/NGS/Bioinformatics/ww_analysis_scripts/Wastewater-genomic-analysis'

# Check if the fastq gen step is completed for the new WW run
# When the NovaSeq (A01290) or NextSeq (VH00770) run is finished and fastq files are copied over to the WW directory, fastqgen_complete.txt appears in the directory

if [ -f "/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/fastqgen_complete.txt" ]
  then
      echo "$(date) : Fastq generation step is completed for run $run_name. Proceed with wastewater analysis"
      
      echo "$(date) : Step 1/3. Set up wastewater sequencing analysis"

      # Define the path to the log file
      log_file1="/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/logs/setup_ww_seq.log"

      # Create the status file if it does not exist
      touch "$log_file1"

      sh $script_dir/setup_ww_seq.sh $run_name | tee -a $log_file1

      echo "$(date) : Checking if the first step completed successfully"
      if
      grep -riwq "ready for downstream bioinformatics analysis" $log_file1
        then
            echo "$(date) : Fastq files names are now cleaned and available for viralrecon"
      else
          echo "$(date) : Oops .. something went wrong. Please check the $run_name run directory"
          exit 1
      fi

      echo "$(date) : Step 2/3. Run viralrecon"
      log_file2="/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/logs/viralrecon.log"

      sh $script_dir/run_viralrecon.sh $run_name $resume_option | tee -a $log_file2

      echo "$(date) : Checking if the viralrecon pipeline completed successfully"
      if
      grep -riwq "Pipeline completed successfully" $log_file2
        then
          echo "$(date) : Viralrecon pipeline completed successfully and BAM files are available for Freyja analysis"
      else
          echo "$(date) : Oops .. something went wrong and viralrecon pipeline stopped"
          exit 1
      fi

      echo "$(date) : Step 3/3. Run Freyja analysis"
      log_file3="/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/logs/freyja.log"

      sh $script_dir/run_freyja.sh $run_name | tee -a $log_file3
      
      echo "$(date) : Checking if freyja analysis completed successfully"
      if
      grep -riwq "Freyja analysis post-processing completed" $log_file3
        then
        echo "$(date) : Freyja analysis completed successfully"
      else
          echo "$(date) : Oops .. something went wrong and Freyja analysis stopped"
          exit 1
      fi
      
else
  echo "$(date) : Fastq generation step is not yet completed for run $run_name."
  exit 1
fi


