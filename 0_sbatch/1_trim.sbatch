#!/bin/bash
#SBATCH --job-name=trim     # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=4        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=4G         # memory per cpu-core (4G is default)
#SBATCH --time=05:00:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-type=end          # send email when job ends
#SBATCH --mail-user=user@princeton.edu

# using trimmomatic version 0.39

cd WORKING_DIR

java -Xmx8000m \
    -jar JAR_PATH/trimmomatic-0.39.jar \
    PE \
    -threads 4 \
    -trimlog SAMPLE_ID_trimlog \
    -phred33 FASTQ/SAMPLE_ID_1.fastq.gz \
        FASTQ/SAMPLE_ID_2.fastq.gz \
        trimmed/SAMPLE_ID_1.TRIMMED.fastq.gz \
        trimmed/SAMPLE_ID_1.unpaired.fastq.gz \
        trimmed/SAMPLE_ID_2.TRIMMED.fastq.gz \
        trimmed/SAMPLE_ID_2.unpaired.fastq.gz \
        ILLUMINACLIP:ADAPTER_PATH/NexteraPE-PE.fa:1:30:7 \
        SLIDINGWINDOW:4:15 \
        MINLEN:20

exit
