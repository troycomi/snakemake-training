# Cluster execution
A major selling point of snakemake is that once a snakefile is written it can
be easily ported to a variety of backends.  Part of this is specifying and
supporting singularity containers and conda environments.  The other step is
specifying resources. Once that is done we can quickly switch schedulers,
move to the cloud, or run on our laptops.

## localrules
Once we enable cluster execution, all rules will be submitted as jobs by
default.  You may not want all rules submitted, especially quick rules (like
all or a small shell script) or those requiring a network connection
(downloading data).

Any rules specified by name with the localrules directive will run with the
main instance of snakemake instead of being executed through the cluster command.
```
localrules:
    all,
    download_data,
    download_reference,
```

## Resources and threads
Resources in snakemake come in two flavors, one specifying hardware constraints
and one representing logical resources.  We will mainly consider the former,
but touch on logical constraints briefly.  The main hardware resources we need
to specify are time, memory and number of CPUs.

### Threads
CPUs are treated differently and have a dedicated directive `threads`.
We will use this value as input to sbatch as the `cpus-per-task` option.
It is specified as an integer and can be used in the shell command:
```python
rule trim:
    # ...
    threads: 4

    shell:
        'java -Xmx8G '
            '-jar /usr/local/share/trimmomatic-0.39-0/trimmomatic.jar '
            'PE '
            '-threads {threads} '
    # ...
```
Threads is special because it also has implications for local execution.  By
default, snakemake will try to use all cores on a machine for running rules.
You can constrain that with the -c or -j option.  If my machine has 4 cores,
snakemake will run as many jobs as possible until all 4 cores are used.  While
I could sort 4 bams at once (each with one thread) I could only perform one
trim at a time.  If I specify only 2 cores, trim will still run, but now
`{threads}` has the value of 2, which is passed to trimmomatic.

If you are mostly concerned with cluster execution, just think of threads as
how you specify the number of cpus for a job.  Threads will default to 1.

### Time and Memory
Time and memory are both specified through the custom `resources` directive.
Their names and units can be set however you choose, but all resources must
be integers.  I typically use `mem` for memory and `time` for time.  Since
they must be integers, I like to use MB for memory and minutes for time to get
the right resolution on my resources.  If you prefer something different you
will have to change the submission script we develop later.

Resources are specified as a directive and can be referenced in the shell
command like so:
```python
rule trim:
# ...
    resources:
        mem=8000,  # MB
        time=90,  # minutes
        # or time=2*24*60  # 2 days

    shell:
        'java -Xmx{resources.mem}m '
```

One interesting feature of resources is that they can accept input functions
which return integers. Here is an example that would not be very good:
```python
def estimate_time(inputs, attempt):
    # IN BYTES
    total_size = sum([os.path.getsize(i) for i in inputs])
    # convert to GB
    total_size /= 2**30
    return int(10 * total_size * 2 ** attempt)

rule something:
    ...
    resources:
        time=lambda wildcards, input, attempt: estimate_time(input, attempt)
```
Here time is calculated as 10 minutes per GB of total input size.  If you allow
multiple restart attempts, each additional attempt will request twice as long.
This is a nice feature but is hard to get working well in practice.

Resources will default to 0, which may be ok for logical resources but will
cause an error on cluster execution.  You can set a default through the command
line, but it's better practice to think about your resources, estimate them,
and refine once you've executed a few samples.
[Reportseff](https://github.com/troycomi/reportseff) can help quickly assess
how well you are utilizing resources with slurm jobs.

### Logical resources
Custom resources can be anything: number of connections to a database, number
of large temporary files to have at once, the total disk space, etc.  Here
are some applications I've used in the past:
- Limit large files.  One step in my workflow required generating large,
  uncompressed files which were immediately consumed and deleted.  If I
  allowed all the samples to run at once I would quickly hit my quota.  Instead
  I added a `large_file` resource to the rule and limited how many could run
  when I invoked snakemake.
- Limit downloads.  To prevent hundreds of wgets from connecting to the same
  server, I added a `wget_connections` resource to keep 10 running at once.
- Limit short jobs.  On Princeton RC clusters, only 2 jobs with runtimes
  less than an hour will be released at once.  We will limit our total job
  submissions to 250 jobs.  If we don't let snakemake know about the short job
  limitation it may create 250 short jobs even though longer running jobs are
  eligible, creating a bottleneck due to the slurm scheduler.  I frequently
  add in the `short_jobs` resource to keep this from happening.

Next, you have to tell snakemake how many of each resource is available.  This
uses the `resources` option and takes a list of `NAME=VALUE` pairs.  For
example, if I only want 5 wget connections at once, I call
```shell
snakemake --resource wget_connections=5
```
This constraint will be considered during execution of the workflow.  If a
resource isn't specified in a rule, its value is set to 0 by default.

## Exercise 6
Add resources to the bwa rule.  If you aren't sure what values to use, you can
start with those in the original sbatch script.  Don't forget threads and be
sure to update the bwa command!

## Cluster execution
With the resources specified, the only remaining changes will be to our
snakemake command.  The main change is the `cluster` option, which tells
snakemake how to invoke sbatch.  We will use:
```
--cluster "sbatch --cpus-per-task={threads} --mem={resources.mem}M \
            --time={resources.time} --output=slurm_out/%x-%A \
            --job-name={rule} --parsable"
```
You should be comfortable with how the threads and resources are replaced in the
command. You would have to change the format if your time and memory don't
refer to minutes and MB.  The job name is taken from the rule name.
**The output directory `slurm_out` must exist before submission or the slurm
job will fail.**  If you prefer your outputs in a different format or directory
you can change those here.  It is important to add the `--parsable` flag so
snakemake can correctly parse the external job id to check the cluster status.

That's really all you need, but we can tune our performance more with the
additional options:
- cluster-status: pass the path to a script which will take an external job id
  and return "success" or "failed".  Must be executable.
- latency-wait: how long (in seconds) to wait for missing files. The default,
  5 seconds, may be too short for some NFS's.  120 is safer and doesn't
  affect performance much.
- jobs: The maximum number of cluster jobs to run at once.  250 is far from the
  cluster max and allows me to run several different pipelines at once.
- max-jobs-per-second:  Maximum number of jobs to submit per second.  Can use
  a float, e.g. 0.1 to submit a job every 10 seconds.
- local-cores: number of threads to use on the head node.
- resources: specify any custom resources as key=value pairs.

Since our command is getting complex, it's time to introduce profiles.

## Profiles
Profiles are configurations that tell snakemake how to interact with the
underlying compute engine. The idea is you can use this same profile for all
of your workflows and when you distribute the workflow, the user only needs
to touch the profile for their scheduler.  There are cookie cutter versions
[available](https://github.com/Snakemake-Profiles/slurm), but we will build
our own since it is more transparent.  The slurm-status.py script is from
that repository.

Profiles are directories which contain a config.yaml file at a minimum.  That
file lists the command line options to use with snakemake.  The basic format
is that `--key value` on the command line becomes `key: value` in the yaml
file.  It's good practice to use the long argument names to keep the code self
documenting.  

This repo has a `princeton_rc` profile with values I typically use in my
workflows on slurm schedulers.  Looking at the config.yaml, we have the
basic configuration options:
```yaml
use-singularity: true
use-conda: true
printshellcmds: true

singularity-prefix: "~/snakemake_images"
conda-prefix: "~/snakemake_images"
```
which tell snakemake to use conda and singularity and place the environments
in the home directory.  Placing images in a central location will prevent
additional runs of snakemake from downloading redundant environments.

The remaining options are the cluster command described above and values for
additional options that are reasonable starting points.  If you provide a
profile and the same option in the command line, the command line option will
take precedence.

To use a profile, run snakemake as
```shell
snakemake --profile /path/to/princeton_rc
```
Again, you can use this same command to run all of your workflows with a slurm
scheduler.

## Exercise 7
Remove the BAMs, FASTQ and trimmed directories and try running the workflow
again with the slurm profile:
```
# in snakemake-training/testing
mkdir slurm_out
snakemake --profile ../princeton_rc -s ../4_cluster/Snakefile
```
Monitor the slurm queue (`squeue -u $USER -i 5`),
slurm\_out (`watch -n 5 'ls -lh'`), and the snakemake output using tmux,
or just watch the snakemake output.

If you have reportseff installed (`pip install reportseff`) check the
efficiency with `reportseff` in the slurm\_out directory
