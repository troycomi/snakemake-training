# Wildcards

Wildcards are a powerful but somewhat complex aspect of snakemake.  The general
format is specifying a filename with some format tokens which are interpreted
as wildcards, similar to shell glob wildcards.  For example, if you wanted all
the .txt files in the current directory using bash, you could use
```shell
*.txt
```
where the `*` tells the shell to accept any type and number of characters.
The (roughly) equivalent format in snakemake is
```python
'{filename}.txt'
```
where `{filename}` is the wildcard, which again accepts any type and number
of characters.

## Flow of wildcards
When snakemake is given a target to build, the first step is to decide which
rule produces output that will satisfy the target.  Next, any wildcards in the
output are evaluated and used to specify input files.  This is worth repeating,
while files are generated from input to output, *wildcards are evaluated from
output to input*.  When we discuss input functions and other directives, it's
still true that the output is evaluated first.

The main implication is that all wildcards in input files must have matches
in output files.  Let's consider a simple rule to sort a file:
```python
rule sort:
    input: '{sample}.unsorted.txt'
    output: '{sample}.sorted.txt'
    shell: 'sort {input} > {output}'
```

When you target `abc.sorted.txt`, snakemake decides that the rule `sort` matches
and further matches the wildcard `sample` to abc.  It then looks at the input,
and matches the sample wildcard to 'abc', creating an job from the rule:

```python
rule sort:
    input: 'abc.unsorted.txt'
    output: 'abc.sorted.txt'
    shell: 'sort abc.unsorted.txt > abc.sorted.txt'
```
At this point, if abc.unsorted.txt didn't exist, the process starts again
or, if no rules output the file, an exception is raised.

Another limitation is that all outputs must contain the same wildcards.  The
following wouldn't be allowed:
```python
rule process:
    output:
        'process_{sample}_{read}.txt',
        'log_{sample}.txt'
```
Several sample, read pairs would be writing to the same log.  Snakemake raises
an error in this case as an output file is not uniquely determined.

## Wildcards for building outputs
Since snakemake evaluates the workflow 'backwards', it is initially challenging
to think about how to request something like "all outputs given my inputs",
which is a common analysis task.  The first step is to find all the input
wildcards.  This can be done with a static list, as we have here:
```python
samples = ['S2']
replicates = ['1', '2']
sorting = ['csorted', 'nsorted']
```
or similarly from an external file listing or configuration.  You can also
automatically detect wildcards from a file listing using the snakemake function
`glob_wildcards`.

Let's continue with the sorting rule from above.  If our directory listing
looked like:
```shell
abc.unsorted.txt
def.unsorted.txt
ghi.unsorted.txt
jkl.unsorted.txt
```
Running `glob_wildcards('{sample}.unsorted.txt')` returns a wildcards object
of lists for each wildcard.  Here, we would have:
```
Wildcards(sample=['abc', 'def', 'ghi', 'jkl'])
```
That list can then be used to construct outputs with the snakemake function
`expand`.  Overall, the top of our file would be
```python
wc = glob_wildcards('{sample}.unsorted.txt')  # get all wildcards
outputs = expand('{sample}.sorted.txt', sample=wc.sample)  # build all outputs
rule all:
    input: outputs
```
Now if we add more files to our directory, the targets will be automatically
built!  Remember, you request all of the **outputs** of your workflow in the
rule all.

## Exercise 4
Why can't we use `glob_wildcards` in this example workflow? Can you think of
how to get all the sample names?

## Ambiguous rules
Recall in our last Snakefile, we had bwa output to `BAMs/SAMPLE_ID.bam` and
sort\_bam output `BAMs/SAMPLE_ID_csorted.bam`.  Replacing the SAMPLE ID with
a wildcard, we have:
```python
rule bwa:
    output: 'BAMs/{sample}.bam'
    # ...
rule sort_bam:
    input: 'BAMs/{sample}.bam'
    output: 'BAMS/{sample}_csorted.bam'
```
Consider matching those wildcards to `BAMs/abc_csorted.bam`.  Clearly
we can match with sort\_bam: `BAMs/{abc}_csorted.bam`.  Under the hood, snakemake
is using the re package to match wildcards to anything, so perhaps surprisingly
bwa can also match as `BAMs/{abc_csorted}.bam`!  Snakemake detects this and
will throw an error, giving some recommendations.  We could constrain the
sample wildcard, by say excluding all underscores `[^_]+` or give priority to
sort\_bam rules.  However, the easiest method is to just put the sorted bams
in a separate directory.  The hierarchical structure is easier to work with and
it's the least likely for error.

## Params
There's nothing stopping us from using multiple wildcards. Looking
at the url of our input data, it seems like we should have a wildcard for
the sample, another for the replicate, and the read of our paired read:
```python
{base_url}/S2_STARRseq_rep1_2.fastq.gz
#    sample^     replicate^ ^read
```
So we can start adding our wildcards to the download\_data rule:
```python
rule download_data:
    output:
        'FASTQ/{sample}_{replicate}_{read}.fastq.gz',
```
but how do we get the url?  We don't want to set it as input since that would
cause a missing input exception during DAG building.  We need to use another
directive, `params`.  Params are additional, non-file, string inputs to rules.
Because output wildcards are always evaluated first, we can use the same
wildcards in our url param:
```python
    params:
        url='/{sample}_STARRseq_rep{replicate}_{read}.fastq.gz'
```
Wildcards don't have to match between rules.  Once we have our FASTQ downloaded,
we can use another wildcard for the input to the trim rule:
```python
    input:
        'FASTQ/{file}_1.fastq.gz',
        'FASTQ/{file}_2.fastq.gz',
```
Now `{file}` will match what was `{sample}_{replicate}`.  It can be
advantageous because now the rule will match any fastq file pair and could be
used in other workflows.  While you can (and I do this here), switching
wildcard names will generally make your workflow harder to follow.

## Input functions
Frequently you will have to do more than format a string based on your
wildcards.  Let's say we had several reference genomes that we wanted to select
based on the sample name.  One way to do this is through input functions.
These are python functions that take wildcards as arguments.  Input functions
can also be used in other directives and can take additional arguments like
inputs, outputs, and attempt.  

Looking at our sort\_bam command, we see two nearly identical commands to build
the two sorted outputs
```python
    output:
        csort='BAMs/SAMPLE_ID_csorted.bam',
        nsort='BAMs/SAMPLE_ID_nsorted.bam',

    shell:
        'samtools sort {input} > {output.csort} \n'
        'samtools sort -n {input} > {output.nsort}'
```
Let's change that to take an input function as a parameter to decide if the
'-n' flag should be added.  First, the output with wildcards is
```python
    output:
        'sorted/{file}_{sorting}.bam',
```
We need a function to check if the sorting is nsorted or csorted, and return
'-n' when it is nsorted.  Easy enough:
```python
def sorting_arg(wildcards):
    if wildcards.sorting == 'nsorted':
        return '-n'
    return ''
```
To use this as an input function, we add it to our params as
```python
    params:
        sorting=sorting_arg
```
and the shell command is now:
```python
    shell:
        'samtools sort {params.sorting} {input} > {output}'
```
The advantage of this implementation is that each sorting can be generated
independently, decreasing wall time and possibly eliminating one sorting
if it is no longer needed.

Input functions can be any function, but most often I use them to aggregate
files or select a value from a dictionary.

## Exercise 5
Replace the hard coded input and output files of the bwa rule with wildcards.
Try running with `snakemake -nq` to make sure you have valid syntax and all
inputs can be found.  Compare with `Snakemake_final`.

In the testing directory, run `snakemake -s ../3_wildcards/Snakefile -nq`.  Do
the planned jobs and counts make sense to you?
