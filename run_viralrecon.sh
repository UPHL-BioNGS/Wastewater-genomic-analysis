 #!/bin/bash
# if any errors, then exit
set -e

###########################
# Author: Pooja Gupta

USAGE="
Purpose: Bash script to run viralrecon bioinformatic pipeline with wastewater sequencing data.

Usage: run_viralrecon.sh <wastewater sequencing run_name> | tee -a viralrecon.log

Last updated on May 16,2023
"
###########################

echo "$USAGE"
run_name=$1
resume_option=$2

script_dir='/Volumes/NGS/Bioinformatics/pooja/ww_analysis_scripts/Wastewater-genomic-analysis'
analysis_dir='/Volumes/IDGenomics_NAS/wastewater_sequencing'
mkdir -p /Volumes/IDGenomics_NAS/wastewater_sequencing/$run_name/analysis/viralrecon/work

#Creating required folders for analysis
ww_fastq=$analysis_dir/$run_name/raw_data/fastq
out_dir=$analysis_dir/$run_name/analysis/viralrecon
work_dir=$analysis_dir/$run_name/analysis/viralrecon/work
results=$analysis_dir/$run_name/results

infile=${run_name}_samplesheet.csv

echo "$(date) : Run Wastewater sample data with viralrecon for run $run_name"
echo "$(date) : First create input samplesheet for viralrecon pipeline"

if [ ! -f "$out_dir/${run_name}_samplesheet.csv" ]
    then
        echo "$(date) : $infile does not exist. Creating samplesheet required to run viralrecon"
        python $script_dir/conf-files/fastq_dir_to_samplesheet.py $ww_fastq $out_dir/$infile
        echo "$(date) : $infile Samplesheet generated" 
    else echo "$(date) : $infile already exists, starting viralrecon"
fi

#check R1 extension in the python script, if different from default

echo "$(date) : Running viralrecon"
#export SINGULARITY_CACHEDIR=/home/pgupta/singularity
#export NXF_SINGULARITY_CACHEDIR=/home/pgupta/singularity
export APPTAINER_CACHEDIR=/home/pgupta/apptainer
export NXF_APPTAINER_CACHEDIR= /home/pgupta/apptainer

#Use UPHL_viralrecon.config to update Pangolin container, if needed

if [ "$resume_option" = "-resume" ]
then
    nextflow run nf-core/viralrecon -name ${run_name} -resume ${run_name} --input $out_dir/$infile \
                                    --primer_set_version 5.3.2 \
                                    --outdir $out_dir \
                                    --nextclade_dataset false \
                                    --nextclade_dataset_tag false \
                                    --schema_ignore_params 'genomes,primer_set_version' \
                                    --multiqc_config $script_dir/conf-files/new_multiqc_config.yaml \
                                    -params-file $script_dir/conf-files/UPHL_viralrecon_params.yml \
                                    -c $script_dir/conf-files/UPHL_viralrecon.config \
                                    -w $work_dir
else
nextflow run nf-core/viralrecon --input $out_dir/$infile \
                                --primer_set_version 5.3.2 \
                                --outdir $out_dir \
                                --nextclade_dataset false \
				                --nextclade_dataset_tag false \
                                --schema_ignore_params 'genomes,primer_set_version' \
                                --multiqc_config $script_dir/conf-files/new_multiqc_config.yaml \
                                -params-file $script_dir/conf-files/UPHL_viralrecon_params.yml \
                                -c $script_dir/conf-files/UPHL_viralrecon.config \
                                -w $work_dir
fi

echo "$(date) : Copying variant long table result file to $results folder"
cp $out_dir/variants/ivar/variants_long_table.csv $results/${run_name}_variants_long_table.csv

echo "$(date) : Copying pangolin result files to the $results folder after merging individual pangolin result files" 
cat $out_dir/variants/ivar/consensus/bcftools/pangolin/*.csv | awk '!a[$0]++' > $results/${run_name}_viralrecon_lineage_report.csv

echo "$(date) : Copying multiqc result files to the results folder"
cp $out_dir/multiqc/multiqc_report.html $results/${run_name}_multiqc_report.html
cp $out_dir/multiqc/summary_variants_metrics_mqc.csv $results/${run_name}_summary_variants_metrics_mqc.csv

echo "$(date) : Cleaning up...removing the work directory"
rm -r $work_dir