# snakemake-training
> Increasingly complete example bioinformatics workflow

Before you arrive, please make sure you have an account on
[adroit](https://researchcomputing.princeton.edu/get-started/get-account) or
another Princeton cluster. We will use ssh and work on the command line.  Also
make sure you have
[installed snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html)
into a dedicated conda environment, on adroit:
```shell
hostname
# adroit5
module load anaconda3/2022.5
conda create -n snake -y
conda activate snake
conda config --env --add channels bioconda
conda config --env --add channels conda-forge
conda install snakemake-minimal -y
snakemake --version
# 7.16.0
```

You can view the presentation [here](https://docs.google.com/presentation/d/1t59lCCWfZOwfAq9HvE2KB5uhTL7S10EH6xNEygGJ1Wg/edit?usp=sharing).
