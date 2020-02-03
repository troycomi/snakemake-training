#!/bin/bash
#SBATCH --job-name=sort          # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=4        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=4G         # memory per cpu-core (4G is default)
#SBATCH --time=05:00:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-type=end          # send email when job ends
#SBATCH --mail-user=user@princeton.edu

# using samtools version 1.3

cd WORKING_DIR/BAMs/

samtools sort  SAMPLE_ID.bam   > SAMPLE_ID_csorted.bam

samtools sort -n SAMPLE_ID.bam > SAMPLE_ID_nsorted.bam

exit
