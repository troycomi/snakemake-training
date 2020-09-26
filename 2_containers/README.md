# Containers
We now have a workflow specifying all commands needed to generate our output
on any system.  However, we have several software dependencies which make
reproduction and distribution of our workflow more difficult.  If you try
running `snakemake` now you will run into an error invoking samtools.
Common methods for handling dependencies in HPC environments include modules
or site-wide installations of common software.  Even if you put this workflow
on a cluster with all dependencies installed, they may not be the correct
version.

To get this workflow running, we will add several singularity containers for
all non-standard software.

## Container Basics
Docker containers package a certain version of software with all the
dependencies required to run it.  Effectively, you get a small virtual machine
that is specifically designed for one piece of software.  Singularity can
use docker files and works without root access, so it is available on HPC
systems.

Conda environments specify several python or R packages for running scripts.
Not only do you easily install all dependencies, you can maintain several
versions of software on the same machine.

What this means as a user is you can guarantee a command works the same every
time you run it by explicitly linking a rule to a container or environment.
Regardless of updates to the system, the same version will run in the container.
When you distribute your workflow or move systems, the pipeline functions
exactly the same because all dependencies are specified.

Generally, try to run any non-standard software from a container.  Specify the
container as precisely as possible, e.g. `samtools:v1.3` instead of `samtools`.
The latter option will always pull the latest build which can cause your
workflow to complete with two different versions of software without you
noticing!

Containers and environments can only be built on the head node as they require
network connections.  If you can't run the main snakemake instance on the head
node, you can add the option `--create-envs-only` to just download containers.
Running that first on the head node, will ensure containers are available when
subsequent runs are performed on worker nodes.

All containers and environments are hashed and stored in unique, digested names
based on their content.  If an environment file changes, a new environment is
created.  By default, these environments are kept in the `.snakemake` directory
in the snakemake working directory.  If you specify a workflow with relative
paths, this will lead to needless duplication of distributions!  Instead,
specify the location, either with `shadow-prefix` for the entire `.snakemake`
directory or with `conda-prefix` and `singularity-prefix` for just environments.
We will add these to our profile later.

## Singularity directives
Let's convert the recommended versions in comments to singularity directives.

If you search for 'samtools docker' you should find a link to docker hub
from [biocontainers](https://hub.docker.com/r/biocontainers/samtools/).
The pull command on the right will always get the latest version, but since
we are specifically looking for version 1.3, let's look at the
['tags' section](https://hub.docker.com/r/biocontainers/samtools/tags).
From there, we can find the docker pull command:
`docker pull biocontainers/samtools:v1.3_cv3`.
*Even if you want the latest version, I highly recommend setting to the latest
version!* As of this writing, v1.9 is current, so I would use the container
`biocontainers/samtools:v1.9-4-deb_cv1` instead of `biocontainers/samtools`. 
That way when an updated version of software comes out, I can decide if I want
to update or keep the same version throughout my analysis.

To convert the pull command from docker hub to a singularity url, add
`docker://` to the front of container name. So
```shell
docker pull biocontainers/samtools:v1.3_cv3
# becomes
singularity: 'docker://biocontainers/samtools:v1.3_cv3'
# in the snakefile
```
We don't have to perform the pull ourselves, snakemake will make sure it is
present before executing if `use-singularity` is specified.

Within the Snakefile, we add the singularity directive to the rule we want it
applied to:
```python
rule index_reference:
    input:
        'GENOME_PATH/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna'

    output:
        'GENOME_PATH/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.fai'

    singularity: 'docker://biocontainers/samtools:v1.3_cv3'

    shell:
        'samtools faidx {input}'
```
You can also specify an entire workflow to be run in a singularity container
by placing the singularity directive outside of any rules.  Note the argument
is a string and can be a variable.  Later we will move it to the config file.

Hopefully that's the only change you need, but depending on the container you
may have to alter your shell command.  For example, the rule `trim` uses a
java archive file which has to be located *within* the container.
```python
    '-jar JAR_PATH/trimmomatic-0.39.jar '
    # becomes
    '-jar /usr/local/share/trimmomatic-0.39-0/trimmomatic.jar '
```
With a different version, that path would have to change.  This is a container
limitation and shouldn't be the case for larger projects.

## Conda directives
Conda works similarly, except you provide the path to a
[conda environment file](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#sharing-an-environment).
Be sure to include the yaml file in your repository so it travels with
the Snakefile.  We aren't using conda here, but it is very convenient to
swap between versions of python or install several R dependencies within a
pipeline.

## Exercise 2
Add a singularity directive to the bwa rule in the Snakefile in this directory.
Check syntax with `snakemake -nq`.

When you are done, check `Snakefile_final` to compare the path chosen.

## Exercise 3
We can finally run this workflow!  Within a shell, we are going to create a
testing directory and run snakemake from there.  From the project root
```shell
$ pwd
    /path/to/your/snakemake-training
$ mkdir testing
$ cd testing
$ snakemake -s ../2_containers/Snakefile --use-singularity -j 1
#           ^snakefile location          ^for containers   ^limit to one job at a time
```
It should take about 3 minutes to complete and produce the following file tree:
```
.
├── BAMs
│   ├── SAMPLE_ID.bam
│   ├── SAMPLE_ID_csorted.bam
│   └── SAMPLE_ID_nsorted.bam
├── FASTQ
│   ├── SAMPLE_ID_1.fastq.gz
│   └── SAMPLE_ID_2.fastq.gz
├── GENOME_PATH
│   ├── GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna
│   ├── GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.amb
│   ├── GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.ann
│   ├── GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.bwt
│   ├── GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.fai
│   ├── GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.pac
│   └── GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.sa
└── trimmed
    ├── SAMPLE_ID_1.TRIMMED.fastq.gz
    ├── SAMPLE_ID_1.unpaired.fastq.gz
    ├── SAMPLE_ID_2.TRIMMED.fastq.gz
    ├── SAMPLE_ID_2.unpaired.fastq.gz
    └── SAMPLE_ID_trimlog
```

If you try to run the workflow again, snakemake will report that nothing
needs to be done because the final targets (sorted bams) already exist.

## The .snakemake directory
Let's take a look into the hidden `.snakemake` directory in testing:
```
.
├── conda
├── conda-archive
├── locks
├── log
│   └── 2020-01-30T142414.701443.snakemake.log
├── metadata
│   ├── dHJpbW1lZC9TQU1QTEVfSURfdHJpbWxvZw==
│   ├── dHJpbW1lZC9TQU1QTEVfSURfMi51bnBhaXJlZC5mYXN0cS5neg==
│   ├── dHJpbW1lZC9TQU1QTEVfSURfMi5UUklNTUVELmZhc3RxLmd6
│   ├── dHJpbW1lZC9TQU1QTEVfSURfMS51bnBhaXJlZC5mYXN0cS5neg==
│   ├── dHJpbW1lZC9TQU1QTEVfSURfMS5UUklNTUVELmZhc3RxLmd6
│   ├── QkFNcy9TQU1QTEVfSUQuYmFt
│   ├── QkFNcy9TQU1QTEVfSURfbnNvcnRlZC5iYW0=
│   ├── QkFNcy9TQU1QTEVfSURfY3NvcnRlZC5iYW0=
│   ├── R0VOT01FX1BBVEgvR0NGXzAwMDAwMTIxNS40X1JlbGVhc2VfNl9wbHVzX0lTTzFfTVRfZ2Vub21pYy5mbmE=
│   ├── R0VOT01FX1BBVEgvR0NGXzAwMDAwMTIxNS40X1JlbGVhc2VfNl9wbHVzX0lTTzFfTVRfZ2Vub21pYy5mbmEuc2E=
│   ├── R0VOT01FX1BBVEgvR0NGXzAwMDAwMTIxNS40X1JlbGVhc2VfNl9wbHVzX0lTTzFfTVRfZ2Vub21pYy5mbmEucGFj
│   ├── R0VOT01FX1BBVEgvR0NGXzAwMDAwMTIxNS40X1JlbGVhc2VfNl9wbHVzX0lTTzFfTVRfZ2Vub21pYy5mbmEuYnd0
│   ├── R0VOT01FX1BBVEgvR0NGXzAwMDAwMTIxNS40X1JlbGVhc2VfNl9wbHVzX0lTTzFfTVRfZ2Vub21pYy5mbmEuYW1i
│   ├── R0VOT01FX1BBVEgvR0NGXzAwMDAwMTIxNS40X1JlbGVhc2VfNl9wbHVzX0lTTzFfTVRfZ2Vub21pYy5mbmEuYW5u
│   ├── R0VOT01FX1BBVEgvR0NGXzAwMDAwMTIxNS40X1JlbGVhc2VfNl9wbHVzX0lTTzFfTVRfZ2Vub21pYy5mbmEuZmFp
│   ├── RkFTVFEvU0FNUExFX0lEXzEuZmFzdHEuZ3o=
│   └── RkFTVFEvU0FNUExFX0lEXzIuZmFzdHEuZ3o=
├── shadow
└── singularity
    ├── 1e6276c6bfbfc474c05fd4152e29050b.simg
    ├── 22d994da3665d19476abf4b6d5691915.simg
    └── 530277b0d7b8d64ee049c9c7a2b65e6b.simg
```

Snakemake generates several files used for persistence between executions. 
The log contains all the output printed to terminal.  Metadata is created for
each output file and contains encoded data on the modification time, dependent
files, and other information used when deciding if a file needs to be created.
Singularity has all the singularity images.  If you want to poke inside an
image you can use `singularity shell <image name>.simg`.  The image names are
hex digests of the singularity container contents.  If we used a conda
directive, the conda environments would be in the conda folder, again encoded
as hex digests of the conda yaml contents.  If you change the yaml file, a new
environment will be created.

Mostly you should know that a lot of files can be produced for larger runs and
the logs can end up taking up a lot of space.  As long as no instance of
snakemake is currently running you can delete this folder.  However, any
containers will be downloaded again before the next run.  Later, we will move
the containers to a separate folder and the .snakemake directory will primarily
have logs in it.
