# Initial Snakefile

Here is the first example of translating the shell files into a snakefile.  We
have directly converted the code so all files are still hard coded and versions
are not enforced.

## Snakemake Basics
Snakemake adds declarative code to define rules describing how to create 
output files from input files.  Declarative code tells the computer what needs
to be done instead of how to do something.  You describe the desired results
instead of listing exactly how to generate them. Similar to GNU make,
snakemake determines which rules to execute in order to produce given targets.
With our example workflow, we request or target the outputs of step 3,
snakemake will determine all steps are required and run them in order.

Unlike GNU make, snakemake is much easier to read and follows pythonic syntax.
It's easy to interface snakemake with large computation engines and handle
thousands of samples.

## Rule Syntax
The general format of a rule is
```python
rule {rule_name}:
    input: {list of inputs}

    output: {list of outputs}

    shell: {shell command as string}
```

The input and output directives use a special list class which supports either
list or dictionary syntax.  If you have two files as input, the following
are both valid:
```python
rule list_input:
    input:
        'file1.txt',
        'file2.txt'
```

```python
rule dictionary_input:
    input:
        first_file='file1.txt',
        second_file='file2.txt',
```
In the second example, `input['first_file']` and `input[0]` both refer to
`file1.txt`.  Which syntax you use depends on the situation and what is
clearer.

Shell directives have a richer set of operations.  Snakemake will take the
string and perform substitutions of format tokens, similar to python 3
f-strings.  One consequence of this behavior is to get the `first_file` from
above in a shell directive, you use `{input[first_file]}` without the quotes.

Let's look at a rule to make a sandwich with file1 concatenated with file2,
and another copy of file1 at the end.  When we are done we want to delete
file2 from the file system.
```python
rule sandwich:
    input:
        first_file='file1.txt',
        second_file='file2.txt',

    output:
        'sandwich.txt'
        
    shell:
        'cat {input} '  # combine first and second file
            '{input[first_file]} '  # along with another copy of first
            '> {output}\n'  # send to output
        'rm {input[second_file]}'
```
Let's walk through the shell command processing step by step.  First,
the format tokens will be replaced by their values.  If you just list
`{input}` or `{output}` snakemake will list all values joined with a space.
```python
shell:
    'cat file1.txt file2.txt '
    #    ^ {input} expanded^
        'file1.txt '
        '> sandwich.txt\n'
    'rm file2.txt'
```
Next, python treats the strings as though they are in a block and concatenates
them together:
```python
shell:
    'cat file1.txt file2.txt ''file1.txt ''> sandwich.txt\n''rm file2.txt'
```
And the adjacent single quotes are 'removed':
```python
shell:
    'cat file1.txt file2.txt file1.txt > sandwich.txt\nrm file2.txt'
```

When all the strings are combined and formatted, the final command will be
```shell
cat file1.txt file2.txt file1.txt > sandwich.txt
rm file2.txt
```
Note that if the trailing spaces and \n were not present, the command
would instead be:
```shell
cat file1.txt file2.txtfile1.txt> sandwich.txtrm file2.txt
```
so the spaces and newlines must be placed carefully.  Input and output
directives are parsed like lists, so you only need to separate the entries
with a comma.

When dealing with more complex shell operations or awk commands, remember
to escape quotes (`\'`) and use double braces (`{{`) for single braces (`{`)
in the output.  E.g.
```python
shell:
    'awk \'BEGIN {{ print "hello" }}\''
```
becomes
```shell
awk 'BEGIN { print "hello" }'
```

Use `snakemake -p` to see which commands are run for each rule.

## Snakefiles and Rules
The simplest project organization is to place all rules in a single file,
called `Snakefile`.  When invoked, snakemake will automatically look for and
load a Snakefile in the current directory.  When no other target is specified,
the first rule (usually called 'all') is made.

Good practice is to include all 'final' outputs in the rule all and then
detail each rule in the order of the workflow.

Generally, each rule should do one thing.  Consider `0_download.sh`:
```shell
# download files
wget -q -O - $reference_url | gunzip -c > $reference_file

# using samtools version 1.3
samtools faidx $reference_file

# using bwa version 0.7.16a-r1181
bwa index -a bwtsw $reference_file
```

This downloads a reference sequence and then indexes it for following steps.
Eventually we will use singularity for dependencies like samtools and bwa,
so the 2 indexing steps should be split into two rules to keep containers
simple. Additionally, if the steps were separate and analysis was stopped
after downloading, snakemake would detect the fna file exists and skip
downloading it.

## EXERCISE 1
Using the Snakefile in this folder, add in a rule for step 2, `2_align.sbatch`.
Determine what the input and output files are and fill those directives.
Copy over the command and replace files with `{input}` and `{output}` tokens.

When you are done, check the output of `snakemake -nq` to ensure you have no
syntax errors.  Then run `snakemake -np` to see what the command output is for
the bwa rule.  Compare to `Snakefile_final` in this folder, did you get all
four inputs? One is implicitly used by bwa but snakemake won't know to generate
it if it's not an input!


## Executing Snakemake
As mentioned previously, invoking snakemake with no arguments will cause it to
use the file named Snakefile in the current directory and target the first rule
for generating outputs.  Alternatively, targets may be specified directly as
command line arguments.  Snakemake has [several options](https://snakemake.readthedocs.io/en/stable/executing/cli.html#all-options)
but I most commonly use the following:
- n: perform a dry run, listing which rules are needed to create the target
  without actually executing them.  Useful for checking syntax and the expected
  number of rules are found and executed.
- q: quiet mode.  Suppress most output of snakemake except for the rule counts.
  I almost always run `snakemake -nq` prior to starting a run!
- r: state the reason for running a rule.  Useful for when *more* rules are
  scheduled to run than you expect.  If a rule has several inputs, will tell
  you which ones have updated and are causing a rule to 'rerun'.
- p: list prompt.  Show the shell command that would run for each rule.  Handy
  for debugging or checking workflows, but quickly gets too verbose for complex
  rules.
- use-singularity/use-conda.  If you specify a conda environment or singularity
  container for a rule, you have to run snakemake with the respective option
  for snakemake to actually use them.
- snakefile: specify the path to the snakefile
- j, cores, jobs: the number of cores to use (locally) or jobs to run at once
  (on a cluster)
- cluster: specify command for cluster submission.  See part 4 for details.
- configfile: specify additional config files
- directory, d: specify the base, working directory

There are clearly several options that will make your snakemake command quite
long!  To better distribute and reproduce your runs, we will use profiles
later and pass them with the `profile` option.
