# SBATCH scripts

These are the starting workflow files.  They contain a common series of steps
in bioinformatics pipelines.  Namely downloading files, removing sequencing
tags (trimming), aligning to a reference sequence, and sorting the aligned
sequences for additional analyses.

The order of execution is dictated by the user, who should follow them
sequentially.  There are several positive aspects of each file including
well documented names and versions of software, but all filenames are hard
coded into the scripts.  While software versions are specified in the comments,
it's up to the user to actually ensure they are installed with the correct
dependencies.

Our goal will be to replace these files with a Snakemake workflow which will
scale to many samples, handle versions and software through singularity and
conda, and automatically build necessary output files based on new inputs.
Once we interface with slurm, we can capture all the SBATCH directives as
well, keeping the resource values (memory and time) next to the corresponding
jobs.

In contrast to accomplishing something similar with bash scripts and array
jobs, Snakemake is much easier to read and write and can continue each step
independently.  We can even tailor the resources for each job depending on
input file size and perform complex scatter-gather operations.

## Exercise 0
- What are some good and bad features of the scripts?
- What would you have to do to analyze another sample?
- Why is “download” a shell script instead of sbatch?

Looking at align.sbatch
- What are the inputs and outputs?
- How is bwa version specified? Enforced?
- Compare the sbatch directives of align and sort.  
  How were resources likely specified between these two steps?
