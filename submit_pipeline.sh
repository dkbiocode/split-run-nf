#!/bin/bash
#SBATCH --job-name=nextflow-pipeline
#SBATCH --output=nextflow_%j.out
#SBATCH --error=nextflow_%j.err
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --partition=day-long-cpu
source $HOME/templates/common.rc

# This is the main Nextflow driver job
# Individual processes will be submitted as separate SLURM jobs

# Set up scratch directory for work files
export NXF_WORK=$TMPDIR # TMPDIR

# Create directory for SLURM job logs
mkdir -p slurm_logs

# Run the pipeline
nextflow run pipeline_v7.nf \
    --input_fastq $1 \
    --num_splits 32 \
    --outdir results \
    -profile slurm_standard \
    -resume \
    -with-report pipeline_report.html \
    -with-trace pipeline_trace.txt \
    -with-timeline pipeline_timeline.html \
    -with-dag pipeline_dag.svg

# Clean up work directory on successful completion (optional)
# if [ $? -eq 0 ]; then
#     echo "Pipeline completed successfully. Cleaning up work directory..."
#     rm -rf $NXF_WORK
# fi
