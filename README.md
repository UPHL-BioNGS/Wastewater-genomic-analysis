# Wastewater Genomic Analysis for SARS-CoV2 Lineage determination

A collection of scripts that UPHL uses to analyze wastewater sequencing data.

This repository provides a suite of bash scripts used for the analysis of wastewater sequencing data, with a primary focus on determining the SARS-CoV2 lineages and their abundance. Initially developed for usage by the UPHL, these scripts can also be used by other researchers interested in similar genomic analyses. 

These scripts set up the required directory structure for analysis, run bioinformatics analysis, and generate submission folders for NCBI. The output of the analysis is an aggregated CSV file containing the lineage data, which can be further used for visualization purposes or deeper data exploration.

Local copy of this github repo is located at /Volumes/NGS/Bioinformatics/pooja/ww_analysis_scripts/Wastewater-genomic-analysis.

## Prerequisites

- Bash
- Python 3.7, 3.8, or 3.9
- [Nextflow](https://www.nextflow.io/)
- [Viralrecon](https://github.com/nf-core/viralrecon)
- [Freyja](https://github.com/andersen-lab/Freyja/tree/main)
- Access to sequencing results directory `/Volumes/IDGenomics_NAS/wastewater_sequencing/`
  
## Directory Structure
```
.
├── data
│   └── wastewater_sequencing
        └── <run_name>
            ├── logs
            ├── raw_data
                ├── 230518-ACSSD32-UT-VH00770-230608_R1_001.fastq.gz
                ├── 230518-AVWRF29-UT-VH00770-230608_R1_001.fastq.gz
                ├── 230518-BCSD20-UT-VH00770-230608_R1_001.fastq.gz
                ├── 230518-CCRWWTF31-UT-VH00770-230608_R1_001.fastq.gz
                ├── 230518-CDSD17-UT-VH00770-230608_R1_001.fastq.gz
                ├── Logs
            ├── SampleSheet_UT-VH00770-230608_wastewater.csv
        └── all_freyja_results
            
```

## Setup and Run Bioinformatics Analysis

The process involves executing the following bash scripts in the given order:
- `WWP_seq_new_run_auto.sh`
- `run_viralrecon.sh`
- `run_freyja.sh`

## Recommended Usage

To run all the steps of the analysis in one single script. This is the recommended way of running the wastewater genomics analysis unless you need to troubleshoot the individual scripts when this one fails. Remember to start a screen as this process can take upto hours depending on the sequence data generated.

Execute the bash script with the sequencing `run_name` as an argument:

```bash
sh run_wwtp_sequencing_analysis.sh <wastewater sequencing run_name>
```
Here are the steps involved in executing the analysis in more detail. Please note that you won't need to run these scripts individually for routine data analysis.

### Step 1: Execute WWP_seq_new_run_auto.sh
Execute the bash script with the sequencing `run_name` as an argument:

```bash
sh WWP_seq_new_run_auto.sh <wastewater sequencing run_name> | tee -a WWP_seq_new_run_auto.sh.log
```

This script initializes the sequencing run analysis. It checks whether the fastq generation step is completed on the in-house DRagen server, sets up the required directory structure for analysis, moves any failed samples to a dedicated directory, renames fastq files for downstream analysis, and prepares fastq files for NCBI submission.

This script also generates a csv file with NCBI submission ID and associated fastq file names which are used for generating NCBI submission templates in Data-flo.

### Step 2: Execute run_viralrecon.sh
Execute the bash script with the sequencing `run_name` as an argument:

```bash
sh run_viralrecon.sh <wastewater sequencing run_name> | tee -a viralrecon.log
```

This script executes the [Viralrecon](https://github.com/nf-core/viralrecon) pipeline with wastewater sequencing data. It checks and creates an input samplesheet required to run the Viralrecon pipeline, runs the pipeline, and copies the resulting files to a dedicated `results` directory.

This script also handles post-pipeline cleanup by removing the `work` directory.

### Step 3: Execute run_freyja.sh
Execute the bash script with the sequencing `run_name` as an argument:

```bash
sh run_freyja_vrn_noBoot_singularity.sh <wastewater sequencing run_name> | tee -a freyja.log
```

This script retrieves BAM files for each sample generated by the Viralrecon tool and performs Freyja analysis. It uses BAM files after the ivar primer trimming step and generates Freyja demultiplexed lineage data. It then aggregates the lineage data and creates a lineage plot. Finally, it copies the aggregated lineage results to the `results` directory.

## Note

You may need to adjust the `SINGULARITY_CACHEDIR` and `NXF_SINGULARITY_CACHEDIR` environment variables according to your system configuration in the `run_viralrecon.sh` script.

The Viralrecon pipeline requires a configuration file (`UPHL_viralrecon.config`), parameters file (`UPHL_viralrecon_params.yml`), and MultiQC configuration file (`new_multiqc_config.yaml`). These should be located in `./conf-files/` directory relative to where the script is run.

The Freyja tool requires the `uphl-freyja-latest.simg` singularity container image. This image can be pulled from Quay ('https://quay.io/repository/uphl/freyja')

After completion of bioninfromatic analysis, the directory strcuture will look like this:
```
.
├── data
│   └── wastewater_sequencing
│       └── <run_name>
            ├── analysis
                ├── freyja
                └── viralrecon
            ├── failed_samples
            ├── fastqgen_complete.txt
            ├── freyja_demix_status.txt
            ├── logs
                ├── freyja.log
                ├── viralrecon.log
                └── WWP_seq_new_run_auto.log
            ├── ncbi_submission
            ├── raw_data
                ├── fastq
                    ├── 230518-ACSSD32-UT-VH00770-230608_R1_001.fastq.gz
                    ├── 230518-AVWRF29-UT-VH00770-230608_R1_001.fastq.gz
                    ├── 230518-BCSD20-UT-VH00770-230608_R1_001.fastq.gz
                    ├── 230518-CCRWWTF31-UT-VH00770-230608_R1_001.fastq.gz
                    └── 230518-CDSD17-UT-VH00770-230608_R1_001.fastq.gz
                └── Logs    
            ├── results
                ├── UT-VH00770-230608_freyja_lin_dict_long_df_lingrps_final.csv
                ├── UT-VH00770-230608_lineage_counts.csv
                ├── UT-VH00770-230608_lineages_aggregate.tsv
                ├── UT-VH00770-230608_multiqc_report.html
                ├── UT-VH00770-230608_summary_variants_metrics_mqc.csv
                ├── UT-VH00770-230608_variants_long_table.csv
                └── UT-VH00770-230608_viralrecon_lineage_report.csv
            ├── SampleSheet_UT-VH00770-230608_wastewater.csv
            ├── UT-VH00770-230608_sra_upload_metadata.csv
            ├── UT-VH00770-230608_biosample_upload_metadata.csv
            ├── UT-VH00770-230608_ncbi_submission_info.csv
            ├── UT-VH00770-230608_wastewater_sample_list.csv
            └── 
        └── all_freyja_results
```

# Wastewater Lineage Data Aggregator

This script aggregates lineage data from wastewater sequencing. It takes the latest sequencing run results (`new_run_name_dir`), cleans it up (adds collection date, lat-long data), and merges them with previous lineage abundance results to output an aggregated CSV file that can be uploaded into the Wastewater Microreact project.

## Configuration

Before running the script, you may need to configure the following parameters in the `config` dictionary defined in the `main` function:

- `wastewater_seq_dir`: Directory path of the wastewater sequencing data.
- `lat_long_file`: File path of the latitude and longitude data.
- `all_freyja_results_dir`: Directory path where all the freyja results are stored.
  
The script currently includes default values for these parameters used at UPHL and doesn't need any modifications.

## Custom Helper Functions

The script includes some custom helper functions:

- `check_abundance_sum(df)`: Checks if the abundance values by group (sample_id, collection_date) sum to 1. If the sum of abundances is greater than 1, it prints a message indicating potential duplicates or other inconsistencies.
- `remove_duplicates(df)`: Removes duplicate entries based on sample_id, collection_date, and lineages columns.
- `save_output(df, output_dir, output_file)`: Saves the output data frame to a CSV file.

## Example

Execute the python script with the two arguments:

- `new_run_name_dir`: Directory name of the new sequencing run results.
- `old_res_date`: Date of the old lineage abundance results.

```bash
python freyja_old_new_res_merge.py new_run_directory old_results_date
```
The final output csv file after this step can be uploaded to Microreact for visualization.
For more information about the script and its functionality, refer to the inline comments within the code.

# Contribution

Contributions are welcome. Please ensure that any changes are made in a separate branch, and a detailed pull request is created. All updates should be well-documented.

# Contact Information

For any questions, issues, or feedback, please file an issue on the Github repository.
