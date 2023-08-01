#!/bin/bash
# if any errors, then exit
set -e

###########################
# Author: Pooja Gupta

USAGE="
Purpose:
1) This is the first step in script run_wwtp_sequencing_analysis_v2 which sets up directory structure for 
initiating Wastewater sequencing run analysis and any downstream analysis.
3) Generate ncbi submission folder that can be directly used for uploading files to NCBI and create a csv file used for uploading into Data-flo to extract biosample and SRA metadata tables.

Usage:
sh WWP_seq_new_run_auto.sh <wastewater sequencing run_name> | tee -a WWP_seq_new_run_auto.log
Last updated on July 30,2023
"
###########################

echo "$USAGE"

# Get the run name from the command line argument

run_name=$1

# Check if the fastq gen step is completed for the new WW run
if [ ! -f "/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/fastqgen_complete.txt" ]
then
    echo "$(date) : Fastq generation step is not yet completed for run $run_name. Exiting..."
    exit 1
fi
echo "$(date) : Fastq generation step is completed for run $run_name."

# Set directory structure/paths for the new WW run
analysis_dir=/Volumes/IDGenomics_NAS/wastewater_sequencing/${run_name}
echo "$(date) : Analysis directory is $analysis_dir."

echo "$(date) : Creating sub directories for downstream analysis"
mkdir -p $analysis_dir/{ncbi_submission,analysis,failed_samples,results}

mkdir -p $analysis_dir/raw_data/fastq
# Output directory paths
echo "$(date) : Raw fastq files will be stored in $analysis_dir/$run_name/raw_data"
echo "$(date) : Bioinformatics analysis will be stored in $analysis_dir/$run_name/analysis"

# Find the samplesheet for the run
sample_sheet="$(ls $analysis_dir/*_wastewater.csv | head -n 1)"
echo "$(date) : The sample sheet for run $run_name is $sample_sheet"

echo "$(date) : Generating list of wastewater samples from the run sample sheet. Used to fetch matching fastq files in the next step"
# Though, the sample sheet by default will only contain wastewater samples, doing this to avoid additional files such as 'undetermined_*.fastq.gz' to be included in the downstream analysis 
grep -i 'Wastewater' $sample_sheet | cut -f 1 -d ',' > $analysis_dir/${run_name}_wastewater_sample_list.csv

# Fastq files directory source
fastq_dir=$analysis_dir/raw_data
# Fastq files directory destination
ww_fastq=$analysis_dir/raw_data/fastq

echo "$(date) : Copying fastq files from $fastq_dir to $ww_fastq directory to run with viralrecon"
find $fastq_dir -type f -name '*.fastq.gz' -print0 | grep -zf $analysis_dir/${run_name}_wastewater_sample_list.csv| parallel -0 "mv {} $ww_fastq/"

echo "$(date) : Fastq files copied successfully to $ww_fastq"
cd $ww_fastq

# Samples that fail after the run are excluded from downstream analysis. This step is nececssary for running samples with viralrecon otherwise oftentimes, the pipeline fails
echo "$(date) : Moving failed samples from raw_data directory to another directory (failed_samples) based on file size < 1MB"
find $ww_fastq -type f -name "*.fastq.gz" -size -1M -print0 | parallel -0 mv {} $analysis_dir/failed_samples/ 

# Rename fastq files for bioinformatics analysis. Also copy fastq files to NCBI submission directory and rename.
echo "$(date) : Rename fastq files for downstream analysis and for NCBI submission"

# If there are two files (_L001 and _L002) per sample as in the case of P3 flow cell then this step is needed to merge the fastqs from two lanes

#mkdir unmerged
#for sample in $(ls *.fastq.gz | sed 's/_L00[0-9]_R1_001.fastq.gz//' | sort | uniq); do 
#    cat ${sample}_L00*_R1_001.fastq.gz > ${sample}_L001002_R1_001.fastq.gz;
#    for unmerged in ${sample}_L00*_R1_001.fastq.gz; do
#        if [ "$unmerged" != "${sample}_L001002_R1_001.fastq.gz" ]; then
#            mv $unmerged unmerged
#        fi
#    done
#done

for file in *.fastq.gz; do
    echo "$(date) : Copy fastq files to NCBI submission directory"
    cp "${file}" "${analysis_dir}/ncbi_submission/$(echo "${file}" | sed -E 's/_S[0-9]+_L[0-9]+/-UT/')"
    echo "$(date) : Rename fastq files for downstream analysis"
    # Check if the file contains the run_name (won't be true for NextSeq 2000 runs)
    if [[ "${file}" == *"${run_name}"* ]]; then
        # Remove the lane and Set identifiers
        new_name=$(echo "${file}" | sed -E "s/_S[0-9]+_L[0-9]+//")
        echo "${new_name}"
        mv "${file}" "${new_name}"
    else
        # Add the run name and remove the lane and Set identifiers
        new_name=$(echo "${file}" | sed -E "s/_S[0-9]+_L[0-9]+_/-${run_name}_/")
        echo "${file}"
        echo "${new_name}"
        mv "${file}" "${new_name}"
    fi
done

# Remove controls from NCBI submission directory prior to submission
echo "$(date) : Removing positive and negative control fastqs from the NCBI submission directory."
find "${analysis_dir}/ncbi_submission/" -type f -name "CPC*.fastq.gz" -print0 | xargs -0 -r rm --
find "${analysis_dir}/ncbi_submission/" -type f -name "NTC*.fastq.gz" -print0 | xargs -0 -r rm --

echo "$(date) : Fastq files ready for NCBI submission. Fastq filenames have been cleaned"

# Create a CSV file with NCBI submission ID and associated fastq file names, used later in Data-flo for creating NCBI submission template
echo "$(date) : Create a csv file with NCBI submission ID and associated fastq file names which gets uploaded to Data-flo for generating NCBI submission templates"
for file1 in ${analysis_dir}/ncbi_submission/*_R1_001.fastq.gz
do
  sample_id=$(basename "$file1" _R1_001.fastq.gz)
  echo $sample_id
  file2="${file1%_R1_001.fastq.gz}_R2_001.fastq.gz"

  if [ -f "$file2" ]; then  # if the file exists
    echo "Found paired-end fastq file"
    echo "${sample_id},${file1##*/},${file2##*/}" >> ${analysis_dir}/${run_name}_ncbi_submission_info.csv
  else
    echo "Found single-end fastq file"
    echo "${sample_id},${file1##*/}," >> ${analysis_dir}/${run_name}_ncbi_submission_info.csv
  fi
done

echo "$(date) : Fastq files names are now cleaned. Folders and files are in place. You are now ready for downstream bioinformatics analysis and NCBI submission."   
