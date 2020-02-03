#!/bin/bash
#SBATCH --job-name=bwa      # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=4        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=4G         # memory per cpu-core (4G is default)
#SBATCH --time=05:00:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-type=end          # send email when job ends
#SBATCH --mail-user=user@princeton.edu

# using bwa version 0.7.17-3

cd WORKING_DIR

bwa mem \
    -M -t 4 \
    GENOME_PATH/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna \
    trimmed/SAMPLE_ID_1.TRIMMED.fastq.gz \
    trimmed/SAMPLE_ID_2.TRIMMED.fastq.gz \
    > BAMs/SAMPLE_ID.bam

exit
