# snakemake-training
> Increasingly complete example bioinformatics workflow

Before you arrive, please make sure you have an account on
[adroit](https://researchcomputing.princeton.edu/systems-and-services/available-systems/adroit)
and install snakemake into a dedicated conda environment on adroit:
```shell
hostname
# adroit4
module load anaconda3
conda create -n snake -y
conda activate snake
conda config --env --add channels bioconda
conda config --env --add channels conda-forge
conda install snakemake-minimal -y
snakemake --version
# 5.10.0
```

If you are logged into Princeton University Google Apps,
you can view the presentation [here](https://docs.google.com/presentation/d/1YETSQQq_Lthr20hc97miLX18m6DKO87MIseMrqZf-LY/edit?usp=sharing).
