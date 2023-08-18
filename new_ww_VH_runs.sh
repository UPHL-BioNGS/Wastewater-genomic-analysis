#!/bin/bash

USAGE="
Looking for new WW COVID runs on VH00770

new_ww_VH_runs.sh

Last updated August 18, 2023
"

echo -e "$USAGE"

# Getting the directory where this script is for relative paths
# scriptdir=$(echo $0 | sed 's/new_runs.sh//g')

script_dir='/Volumes/NGS/Bioinformatics/pooja/ww_analysis_scripts/Wastewater-genomic-analysis'

# This is going to keep the loop going
while [ -d "/Volumes/NGS/Analysis" ]
do
  # First, getting a list of all the complete runs
  # When the NextSeq (VH00770) run is finished, CopyComplete.txt appears in the directory
  complete_runs=($(ls /Volumes/NGS/Output/VH00770/23*VH00770*/CopyComplete.txt ))
  for complete_run in ${complete_runs[@]}
  do

    # Getting information for the run
    raw_run=$(echo $complete_run | sed 's/\/CopyComplete.txt//g')
    run_date=$(echo $complete_run | rev | cut -f 2 -d "/" | rev | cut -f 1 -d "_")
    run_instrument=$(echo $complete_run | rev | cut -f 2 -d "/" | rev | cut -f 2 -d "_")
    run_name="UT-$run_instrument-$run_date"
    echo "$(date) : $run_name sequencing is complete."

    # Checking to see if this run in the output directory
    sample_sheet=$(ls $raw_run/*csv | head -n 1)

    # Checking for sample sheet, CopyComplete, and RTAComplete
    if [ -n "$sample_sheet" ] && [ -f "$raw_run/CopyComplete.txt" ] && [ -f "$raw_run/RTAComplete.txt" ]
    then
      echo "$(date) : The sample sheet for $run_name is $sample_sheet"
    else
      echo "$(date) : FATAL : Something is missing. Analysis cannot continue."
      if [ -z "$(ls $raw_run/*csv | head -n 1)" ]; then echo "$(date) : FATAL : SampleSheet*csv is missing."  ; fi
      if [ ! -f "$raw_run/CopyComplete.txt" ]               ; then echo "$(date) : FATAL : CopyComplete.txt is missing." ; fi
      if [ ! -f "$raw_run/RTAComplete.txt" ]                ; then echo "$(date) : FATAL : RTAComplete.txt is missing."  ; fi
    fi
    
    # Checking for wastewater and patient samples
    wastewater_check=$(grep -i wastewater $sample_sheet | head -n 1)

    # Checking to see if the analysis has already been run for wastewater samples
    if [ ! -d "/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name" ] && [ -n "$wastewater_check" ]
    then
      echo "$(date) : Wastewater samples were found for $run_name in $sample_sheet, proceed with wastewater analysis"
            
      # Set directory structure/paths for the new WW run

      mkdir /Volumes/IDGenomics_NAS/wastewater_sequencing/${run_name}

      analysis_dir=/Volumes/IDGenomics_NAS/wastewater_sequencing/${run_name}
      echo "$(date) : Analysis directory is $analysis_dir."

      # Copying sample sheet from output to wastewater directory
      cp $sample_sheet $analysis_dir/${run_name}_Samplesheet.csv

      echo "$(date) : Generating list of wastewater samples from the run sample sheet. Used to fetch matching fastq files in the next step"
      grep -i 'Wastewater' $sample_sheet | cut -f 1 -d ',' > $analysis_dir/${run_name}_wastewater_sample_list.csv

      mkdir -p $analysis_dir/raw_data/fastq
      # Output directory paths
      echo "$(date) : Raw fastq files will be stored in $analysis_dir/$run_name/raw_data"
      echo "$(date) : Bioinformatics analysis will be stored in $analysis_dir/analysis"

    # Checking if fastq generation is completed
    
    #if [ -f "$fastq_dir/Logs/FastqComplete.txt" ]
    #then
    #  echo "$(date) : Fastq files for $run_name are ready"
    #else
    #echo "$(date) : Fastq generation for $run_name is still not complete"
    #fi

    # Fastq files directory source is $fastq_dir
    fastq_dir=${raw_run}/Analysis/1/Data/fastq
    # Fastq files directory destination
    ww_fastq=$analysis_dir/raw_data/fastq

    echo "$(date) : Copying fastq files from $fastq_dir to $ww_fastq directory to run with viralrecon"
    find $fastq_dir -type f -name '*.fastq.gz' -print0 | grep -zf $analysis_dir/${run_name}_wastewater_sample_list.csv| parallel -0 "cp {} $ww_fastq/"

    # echo "$(date) : Fastq files copied successfully to $ww_fastq"

    echo "$(date) : Creating sub directories for downstream analysis"
    mkdir -p $analysis_dir/{ncbi_submission,analysis,failed_samples,results,logs}

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
            cp "${file}" "${analysis_dir}/ncbi_submission/$(echo "${file}" | sed -E 's/_S[0-9]+/-UT/')" #for fastqs copied directly from Output folder
            # cp "${file}" "${analysis_dir}/ncbi_submission/$(echo "${file}" | sed -E 's/_S[0-9]+_L[0-9]+/-UT/')" #for fastqs processed via dragen
            echo "$(date) : Rename fastq files for downstream analysis"
            # Check if the file contains the run_name (won't be true for NextSeq 2000 runs)
          if [[ "${file}" == *"${run_name}"* ]]; then
                # Remove the lane and Set identifiers
                new_name=$(echo "${file}" | sed -E "s/_S[0-9]+//") #for fastqs copied directly from Output folder
                # new_name=$(echo "${file}" | sed -E "s/_S[0-9]+_L[0-9]+//") #for fastqs processed via dragen
                
                echo "${new_name}"
                mv "${file}" "${new_name}"
          else
                # Add the run name and remove the lane and Set identifiers
                new_name=$(echo "${file}" | sed -E "s/_S[0-9]+_/-${run_name}_/") #for fastqs copied directly from Output folder
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
  
      echo "$(date) : Step 2/3. Run viralrecon"
      cd $script_dir
      log_file2="/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/logs/viralrecon.log"

      sh $script_dir/run_viralrecon.sh $run_name $resume_option | tee -a $log_file2

      echo "$(date) : Checking if the viralrecon pipeline completed successfully"
      if
      grep -riwq "Pipeline completed successfully" $log_file2
      then
          echo "$(date) : Viralrecon pipeline completed successfully and BAM files are available for Freyja analysis"
      else
          echo "$(date) : Oops .. something went wrong and pipeline stopped"
          exit 1
      fi

      echo "$(date) : Step 3/3. Run Freyja analysis"
      log_file3="/Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/logs/freyja.log"

      sh $script_dir/run_freyja.sh $run_name | tee -a $log_file3


  else
      echo "$(date) : No new runs to be processed"
    fi

  done
  echo "$(date) : Sleeping for 240 minutes"
  sleep 240m
done

echo "$(date) : FATAL : Something happened and the loop ended!"
echo -e "$USAGE"