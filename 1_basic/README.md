# Initial Snakefile

Here is the first example of translating the shell files into a snakefile.  We
have directly converted the code so all files are still hard coded and versions
are not enforced.
## Snakemake Basics
The general format of a rule is
```
rule {rule_name}:
    input: {list of inputs}

    output: {list of outputs}

    shell: {shell command as string}
```

The input and output directives use a special list class which supports either
list or dictionary syntax.  If you have two files as input, the following
are both valid:
```
input:
    'file1.txt',
    'file2.txt'
```

```
input:
    first_file='file1.txt',
    second_file='file2.txt',
```
In the second example, `input['first_file']` and `input[0]` both refer to
`file1.txt`.  Which syntax you use depends on the situation and what is
clearer.

Shell directives have a richer set of operations.  Snakemake will take the
string and perform substitutions of format tokens, similar to python 3 f-strings.
One consequence of this behavior is to get the `first_file` from above in a
shell directive, you use `{input[first_file]}` without the quotes.

Let's look at a rule to make a file with file1 concatenated with file2, and
another copy of file1 at the end.  When we are done we want to delete file2.
```
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
When all the strings are combined and formatted, the final command will be
```
cat file1.txt file2.txt file1.txt > sandwich.txt
#   ^ {input} expanded^
rm file2.txt
```

When dealing with more complex shell operations or awk commands, remember
to escape quotes and use double braces.  E.g.
```
shell:
    'awk \'BEGIN {{ print "hello" }}\''
```
becomes
```
awk 'BEGIN { print "hello" }'
```

Use `snakemake -p` to see which commands are run for each rule.
