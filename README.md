# Wastewater Genomic Analysis for SARS-CoV2 Lineage determination

A collection of scripts that UPHL uses to analyze wastewater sequencing data.

This repository provides a suite of bash and python scripts used for the analysis of wastewater sequencing data, with a primary focus on determining the SARS-CoV2 lineages and their abundance. Initially developed for usage by UPHL bioinformaticians, these scripts can also be adapted by other researchers interested in similar genomic analyses. However, please note the specific directory structure required for running the different steps in the analysis.

The bash scripts set up the required directory structure for analysis, run bioinformatics analysis, and generate submission folders for NCBI. The output of the bioinformatics analysis is an aggregated CSV file containing the lineage data. You will need to run the python script under section [Wastewater Lineage Data Aggregator](#wastewater-lineage-data-aggregator) to complete the workflow as this python script will aggregate lineage data from previous runs with the current sequencing run and generate a CSV file which can be further used for visualization purpose on Microreact or deeper data exploration.

## Prerequisites

- Bash
- Python 3.7, 3.8, or 3.9
- [Nextflow](https://www.nextflow.io/)
- [Viralrecon](https://github.com/nf-core/viralrecon)
- [Freyja](https://github.com/andersen-lab/Freyja/tree/main)
- Access to wastewater sequencing directory `/Volumes/IDGenomics_NAS/wastewater_sequencing/` or your specific output directory
  
## Directory Structure

Here is a basic outline of the project's directory structure:

```
.
├── data
    └── wastewater_sequencing
        └── all_freyja_results
        └── <run_1>
        └── <run_2>
                       
```

## Outdated - DO NOT RUN THE ANALYSIS USING THIS SINGLE SCRIPT 'run_ww_analysis_auto.sh'. Recommended way is to run the analysis scripts individually as detailed below.

To run all the steps of the analysis in one single script, simply execute the bash script in a new screen with `run_name` as an argument

```bash
sh ./run_ww_analysis_auto.sh <wastewater sequencing run_name>
```

You can use the `-resume` flag as an optional argument and it will be passed to [run_viralrecon.sh](run_viralrecon.sh) script and Nextflow will attempt to resume the pipeline. It is a great way of resuming a run without having to start the analysis from scratch. If you don't provide it, `$resume_option` will be empty, and `run_viralrecon.sh` will run without the `-resume` flag, just like before.

```bash
sh ./run_ww_analysis_auto.sh <wastewater sequencing run_name> -resume
```

If the scripts completes successfully, please proceed with python script mentioned below under section [Wastewater Lineage Data Aggregator](#wastewater-lineage-data-aggregator) to get the aggregated result file which can be uploaded in Microreact.

## Important Notes:
Always ensure that the mounted directories are accessible before running the script.
Ensure that you have access to the github repo or it is cloned in your workspace. Local copy of this github repo is currently located at `/Volumes/NGS/Bioinformatics/ww_analysis_scripts/Wastewater-genomic-analysis`.

Executing the bash script `run_ww_analysis_auto.sh` is the recommended way of running the wastewater genomics analysis unless you need to troubleshoot the individual scripts when this one fails. Remember to start a screen as this process can take upto hours depending on the sequence data generated.

Here are the steps involved in executing the analysis in more detail. Please note that you won't need to run these scripts individually for routine data analysis.

## Recommended Usage (last updated July 2025)
### Step 1: Execute detect_new_run_VHrun.sh
Execute the bash script with the name of the sequencing output folder that needs to be processed usually located at `/Volumes/NGS/Output/` with `raw_run' name as an argument:

```bash

bash detect_new_run_VHrun.sh $raw_run

```

This script initializes the sequencing run analysis. It checks whether the sequencing run is completed in the sequencing output directory `/Volumes/NGS/Output/${run_instrument}/${raw_run}`, sets up the required directory structure for analysis, copies over the relevant wastewater fastq files, moves any failed samples to a dedicated directory, renames fastq files for downstream analysis, and prepares fastq files for NCBI submission.

This script also generates a csv file with NCBI submission ID and associated fastq file names which are used for generating NCBI submission templates in Data-flo.

### Step 2: Execute run_viralrecon.sh

Grab the run name from the wastewater sequencing directory.
Execute the bash script with the sequencing `run_name` as an argument:

```bash

log_file1="/Volumes/NGS_2/wastewater_sequencing/$run_name/logs/viralrecon.log"

bash run_viralrecon.sh $run_name | tee -a $log_file1
```

This script executes the [Viralrecon](https://github.com/nf-core/viralrecon) pipeline with wastewater sequencing data. It checks and creates an input samplesheet required to run the Viralrecon pipeline, runs the pipeline, and copies the resulting files to a dedicated `results` directory. 

You can use `-resume` flag as an optional argument and Nextflow will attempt to resume the pipeline.

With `-resume` flag,

```bash
log_file1="/Volumes/NGS_2/wastewater_sequencing/$run_name/logs/viralrecon.log"

bash run_viralrecon.sh $run_name -resume | tee -a $log_file1
```

This script also handles post-pipeline cleanup by removing the `work` directory.

### Step 3: Execute run_freyja.sh
Execute the bash script with the sequencing `run_name` as an argument:

```bash
log_file2="/Volumes/NGS_2/wastewater_sequencing/$run_name/logs/freyja.log"

bash run_freyja.sh $run_name | tee -a $log_file2
```

This script retrieves BAM files for each sample generated by the viralrecon pipeline and performs [Freyja](https://github.com/andersen-lab/Freyja/tree/main) analysis. It uses BAM files after the ivar primer trimming step and generates Freyja demultiplexed lineage data. It then aggregates the lineage data and creates a lineage plot. Finally, it copies the aggregated lineage results to the `results` directory.

## Note

You may need to adjust the `SINGULARITY_CACHEDIR` and `NXF_SINGULARITY_CACHEDIR` environment variables according to your system configuration in the `run_viralrecon.sh` script. 


The [Viralrecon](https://github.com/nf-core/viralrecon) pipeline requires a configuration file [UPHL_viralrecon.config](./conf-files/UPHL_viralrecon.config), parameters file [UPHL_viralrecon_params.yml](./conf-files/UPHL_viralrecon_params.yml), and MultiQC configuration file [new_multiqc_config.yaml](./conf-files/new_multiqc_config.yaml). These are located in [conf-files](./conf-files/) directory relative to where the script is run.

The [Freyja](https://github.com/andersen-lab/Freyja/tree/main) tool requires the `staphb-freyja-latest.simg` singularity container image. Currently, the script automatically pulls in the latest image when its run. If the staph-b freyja container is outdated, please run the 'run_freyja_conda.sh' script by pulling in the latest freyja container using conda and then running the script to get the latest barcodes for the anlaysis.

After completion of bioinformatic analysis, the project has the following directory structure:

```
.
├── data
│   └── wastewater_sequencing
        └── all_freyja_results
│       └── <run_name>
            ├── analysis
                ├── freyja
                └── viralrecon
            ├── failed_samples
            ├── logs
                ├── freyja_demix_status.txt
                ├── freyja.log
                ├── viralrecon.log
            ├── ncbi_submission
                ├── 230518-ACSSD32-UT_R1.fastq.gz
                ├── 230518-AVWRF29-UT_R1.fastq.gz
                ├── 230518-BCSD20-UT_R1.fastq.gz
                ├── 230518-CCRWWTF31-UT_R1.fastq.gz
                └── 230518-CDSD17-UT_R1.fastq.gz
            ├── raw_data
                ├── fastq
                    ├── 230518-ACSSD32-UT-VH00770-230600_R1_001.fastq.gz
                    ├── 230518-AVWRF29-UT-VH00770-230600_R1_001.fastq.gz
                    ├── 230518-BCSD20-UT-VH00770-230600_R1_001.fastq.gz
                    ├── 230518-CCRWWTF31-UT-VH00770-230600_R1_001.fastq.gz
                    └── 230518-CDSD17-UT-VH00770-230600_R1_001.fastq.gz   
            ├── results
                ├── UT-VH00770-230600_freyja_lin_dict_long_df_lingrps_final.csv
                ├── UT-VH00770-230600_lineage_counts.csv
                ├── UT-VH00770-230600_lineages_aggregate.tsv
                ├── UT-VH00770-230600_multiqc_report.html
                ├── UT-VH00770-230600_summary_variants_metrics_mqc.csv
                ├── UT-VH00770-230600_variants_long_table.csv
                └── UT-VH00770-230600_viralrecon_lineage_report.csv
            ├── tmp_ww_list_raw.txt
            ├── UT-VH00770-230600_clinical_sample_list.txt
            ├── UT-VH00770-230600_SampleSheet.csv
            ├── UT-VH00770-230600_SampleSheet_ww.csv
            ├── UT-VH00770-230600_sra_upload_metadata.csv
            ├── UT-VH00770-230600_biosample_upload_metadata.csv
            ├── UT-VH00770-230600_ncbi_submission_info.csv
            ├── UT-VH00770-230600_wastewater_sample_list.csv
        
```

# Wastewater Lineage Data Aggregator

This script needs to be run after you have generated lineage results by running `run_freyja.sh`. The script described below aggregates lineage data across wastewater sequencing runs. It takes the latest sequencing run results from the `$run_name/results` folder,e.g., `UT-VH00770-230600_freyja_lin_dict_long_df_lingrps_final.csv`, cleans it up (adds collection date, lat-long data), and merges them with previous lineage abundance results to output an aggregated CSV file that can be uploaded into the Wastewater Microreact project.

## Configuration

Before running the script externally (not in-house), you may need to configure the following parameters in the `config` dictionary defined in the `main` function:

- `wastewater_seq_dir`: Directory path of the wastewater sequencing data.
- `lat_long_file`: File path of the latitude and longitude data.
- `all_freyja_results_dir`: Directory path where all the freyja results are stored.
  
The script currently includes default values for these parameters used at UPHL and doesn't need any modifications.

## Example

Execute the python script with the two arguments:

- `new_run_name_dir`: Directory name of the new sequencing run results.
- `old_res_date`: Date of the old lineage abundance results. Check the date of the last modified folder at `/Volumes/IDGenomics_NAS/wastewater_sequencing/all_freyja_results/`

```bash
python freyja_old_new_res_merge.py <new_run_directory> <old_results_date>
```
The final output csv file located in `/Volumes/NGS_2/wastewater_sequencing/all_freyja_results/<run_date>` after running the python script can be uploaded to Microreact for visualization.

For more information about the scripts and their functionality, refer to the inline comments within the code.

# Uploading Fastq files to NCBI SRA database

After completion of the bioinformatics analysis, the output file `UT-VH00770-230600_ncbi_submission_info.csv` can be used to create NCBI templates for biosample and SRA submission. Detailed instructions on submitting data to NCBI are located at `https://docs.google.com/document/d/1rGCWnDpGljdLqMs0FZ90TJLPtHRFpwIo-lalLKINn0w/edit?usp=sharing`. This file can only be accessed by anyone within UPHL. 

# Debugging
The scripts provide verbose logs throughout its operation. If there's an issue, the logs will often provide clues about what went wrong. Since 09/01/2023, I have been observing singularity/apptainer related issue when running the pipeline using `run_ww_analysis_auto.sh` at the viralrecon step. The current resolution is to resume and re-run the script using `-resume` flag, until we come up with a better solution to resolve this.

# Contribution

Contributions are welcome. Please ensure that any changes are made in a separate branch, and a detailed pull request is created. All updates should be well-documented.

# Contact Information

For any questions, issues, or feedback, please file an issue on the Github repository.
