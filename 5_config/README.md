# Configuration Files
Looking at the last Snakefile, we have several hard coded variables that
are independent of the workflow that we may want to change later.  What if
we want to change our reference genome? Or the project structure location?
In keeping with the don't repeat yourself principle, we also reuse path
locations several times, like `sorted/{sample}_{replicate}_{sorting}.bam`.

Here we will address these issues using a configuration file.  Similar to
profiles we introduced last time, we want to abstract our particular instance
of a run from our workflow.  The idea is that if you want to redo an
analysis or distribute it, you only have to change the file paths or options
in a config, but the underlying analysis steps will be unchanged.

## The config file
Config files are json or yaml documents that will be converted into a python
dictionary in our Snakefile.  You can create lists, objects and nest as deep
as you need.  Because the snytax gets tiresome and verbose, try to keep nesting
to just a few levels.  I always have a `paths` top level that contains all
the local file system directories.  A `containers` entry is also good to
keep all software versions together.  If you have several options for a command
you can also make the command an entry with each option name as a key-value.

Here's the first few lines of the config.yaml
```yaml
paths:
  reference_fna: "GENOME_PATH/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna"

  raw_fastq: "FASTQ/{sample}_{replicate}_{read}.fastq.gz"
  # ...
urls:
  reference: "ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/215/\
              GCF_000001215.4_Release_6_plus_ISO1_MT/\
              GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.gz"
```
In our rule, we then have
```python
configfile: 'config.yaml'
# I like to set this as a separate variable because I use it a lot
paths = config['paths']

# ...
rule download_reference:
    output:
        paths['reference_fna']

    shell:
        'wget -q -O - {config[urls][reference]} | gunzip -c > {output}'
```
The first line tells snakemake where to find the config file, which causes
it to load the values into the `config` dictionary.  Because I use paths more
than any other value, I usually set it to `paths`.  A point of confusion is that
config keys do not need quotes within a shell directive,
`{config[urls][reference]}` above.  This is because snakemake does additional
processing to the string before making a shell script and is similar to using
named lists for input/output.  When outside of that context or when using
python f-strings, you DO need quotes, `paths['reference_fna']` above.

## Exercise 8
Replace the input, output, and singularity directives of the bwa rule with
values from paths and config.  Use `snakemake -nq` to check if there are
errors parsing the Snakefile.  Check the `Snakemake_final` to compare.

## Exercise 9
In preparation for publication, you decide that all directory names should be
upper case. Where do you need to make changes? Capitalize trimmed and sorted,
then run `snakemake -nq`, how many jobs are required and is it what you expect?

## Exercise 10
You no longer care about nsorted output or replicate 1.  How do you change the
config yaml?

## More config files
You can have multiple configuration files, either by providing additional
configfile directives or through the `configfile` option on the command line.
If you just want to modify one or a few values, you can also set values with
the `config` option.  Values in the config object are set in order and will
overwrite each other.  Consider this situation, each yaml has a variable 
'test' with a value equal to the number in the yaml file, e.g. config2.yaml
has `test: 2`
```python
# Snakefile
configfile: config1.yaml
configfile: config2.yaml
```

```yaml
# profile
configfile: config3.yaml
```

```shell
# snakemake command
snakemake --profile profile --configfile config4.yaml \
    --config test=5 --configfile config6.yaml
```

The final value of test is ill defined and may change in future versions
depending on how options are parsed.  Don't do this!

## Configuration Best Practices
Generally:
- Fewer config files are better than more.  If you must split your config
  be certain you have no overlapping keys or be careful when you load.  Load
  config files in one way (e.g. only in the Snakefile).
- Don't use the config option.  It is hard to document a command line option
  so your work will be harder to replicate.
- While your config paths may not matter for reproducibility, the options and
  version numbers certainly do!  It's important to keep a record of what was
  run and your snakefile and config file (together) can do that.

With version control, I can think of two valid schemes for keeping
configuration and Snakefiles organized with data.
1. Single config file specified in the Snakefile.  Invoke with just the profile
   option and commit to your VCS.  Tag the commit with the date and any other
   important identifying information.  When you need to see how a file was made,
   go back to VCS log and checkout the correct version.  Update or remove tags
   that you don't keep/use.
2. Multiple config files.  Before running the pipeline, commit to VCS and
   record the hash either in the config file or as the config file's name.
   Move config file to the working directory and run snakemake with the profile
   and config file options.  If you remake a directory, also remove the config.

In simple workflows with a single config and Snakefile, either will work.  When
you incorporate subworkflows and multiple config files only option 1 may be
viable.
