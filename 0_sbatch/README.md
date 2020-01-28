# SBATCH scripts

These are the starting workflow files. The order of execution is dictated by the
user, who should follow them in order.  There are several positive aspects of
each file including well documented names and versions of software, but all 
filenames are hard coded into the scripts.  While software versions are
specified in the comments, it's up to the user to actually ensure they are
installed and the correct version.  

Our goal will be to replace these files with a Snakemake workflow which will
scale to many samples, handle versions and software through singularity and
conda, and automatically build necessary output files based on new inputs.
Once we interface with slurm, we can capture all the SBATCH directives as
well, keeping the resource values next to their rules.

In contrast to accomplishing something similar with bash scripts and array
jobs, Snakemake is much easier to read and write and can continue each step
individually.  We can even tailor the resources for each job depending on
input file size and perform complex scatter-gather operations.
