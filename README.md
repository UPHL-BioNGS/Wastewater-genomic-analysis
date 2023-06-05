# Wastewater Genomic Analysis for SARS-CoV2 Lineage determination

A collection of scripts that UPHL uses to analyze wastewater sequencing data.

This repository provides a series of bash scripts to analyze wastewater sequencing data to determine SARS-CoV2 lineages and their abundance. These scripts set up the required directory structure for analysis, run bioinformatics analysis, and generate submission folders for NCBI. 

The process involves executing the following bash scripts in the given order:
- `WWP_seq_new_run_auto.sh`
- `run_viralrecon.sh`
- `run_freyja.sh`

## Prerequisites

- Bash
- Python 3.7, 3.8, or 3.9
- [Nextflow](https://www.nextflow.io/)
- [ViralRecon](https://github.com/nf-core/viralrecon)
- [Freyja](https://quay.io/repository/uphl/freyja)
- Access to sequencing results directory `/Volumes/IDGenomics_NAS/wastewater_sequencing/`

## Setup and Run Bioinformatics Analysis

### Step 1: Execute WWP_seq_new_run_auto.sh
Execute the bash script with the sequencing `run_name` as an argument:

```bash
sh WWP_seq_new_run_auto.sh <wastewater sequencing run_name> | tee -a WWP_seq_new_run_auto.sh.log
```

This script initializes the sequencing run analysis. It checks whether the fastq generation step is completed, sets up the required directory structure for analysis, moves any failed samples to a dedicated directory, renames fastq files for downstream analysis, and prepares fastq files for NCBI submission.

This script also generates a csv file with NCBI submission ID and associated fastq file names which are used for generating NCBI submission templates.

### Step 2: Execute run_viralrecon.sh
Execute the bash script with the sequencing `run_name` as an argument:

```bash
sh run_viralrecon.sh <wastewater sequencing run_name> | tee -a viralrecon.log
```

This script executes the [ViralRecon](https://github.com/nf-core/viralrecon) pipeline with wastewater sequencing data. It checks and creates an input samplesheet required to run the ViralRecon pipeline, runs the pipeline, and copies the resulting files to a dedicated `results` directory.

This script also cleans up the workspace by removing the `work` directory.

### Step 3: Execute run_freyja_vrn_noBoot_singularity.sh
Execute the bash script with the sequencing `run_name` as an argument:

```bash
sh run_freyja_vrn_noBoot_singularity.sh <wastewater sequencing run_name> | tee -a freyja.log
```

This script retrieves BAM files for each sample generated by the ViralRecon tool and performs Freyja analysis. It uses BAM files after the ivar primer trimming step and generates Freyja demultiplexed lineage data. It then aggregates the lineage data and creates a lineage plot. Finally, it copies the aggregated lineage results to the `results` directory.

## To run all the steps in one single script. This will usually be needed to start on a screen on the LW.
Execute the bash script with the sequencing `run_name` as an argument:

```bash
sh run_wwtp_sequencing_analysis.sh < wastewater sequencing run_name >
```

## Note

You need to adjust the `SINGULARITY_CACHEDIR` and `NXF_SINGULARITY_CACHEDIR` environment variables according to your system configuration in the `run_viralrecon.sh` script.

The ViralRecon pipeline requires a configuration file (`UPHL_viralrecon.config`), parameters file (`UPHL_viralrecon_params.yml`), and MultiQC configuration file (`new_multiqc_config.yaml`). These should be located in `../conf-files/` directory relative to where the script is run.

The Freyja tool requires the `uphl-freyja-latest.simg` Singularity container image. This image can be pulled from the Quay ('https://quay.io/repository/uphl/freyja')


# Wastewater Lineage Data Aggregator

This script aggregates lineage data from wastewater sequencing. It takes the latest sequencing run results (`new_run_name_dir`), cleans it up (adds collection date, lat-long data), and merges them with previous lineage abundance results to output an aggregated output CSV file that can be uploaded into a Microreact project.

## Configuration

Before running the script, you need to configure the following parameters in the `config` dictionary defined in the `main` function:

- `wastewater_seq_dir`: Directory path of the wastewater sequencing data.
- `lat_long_file`: File path of the latitude and longitude data.
- `all_freyja_results_dir`: Directory path where all the freyja results are stored.
  
The script currently includes default values for these parameters used at UPHL.

## Custom Helper Functions

The script provides some custom helper functions:

- `check_abundance_sum(df)`: Checks if the abundance values by group (sample_id, collection_date) sum to 1. If the sum of abundances is greater than 1, it prints a message indicating potential duplicates or other inconsistencies.
- `remove_duplicates(df)`: Removes duplicate entries based on sample_id, collection_date, and lineages columns.
- `save_output(df, output_dir, output_file)`: Saves the output DataFrame to a CSV file.

## Example

Execute the python script with the two arguments:

- `new_run_name_dir`: Directory name of the new sequencing run results.
- `old_res_date`: Date of the old lineage abundance results.

```bash
python freyja_old_new_res_merge.py new_run_directory old_results_date
```

For more information about the script and its functionality, refer to the inline comments within the code.
