#!/bin/bash

base_url="http://www.starklab.org/data/arnold_science_2013"
wget -q -O - ${base_url}/STARRseq_input_lib5.2_1.fastq.gz | \
    zcat | head -n 4000 | gzip > FASTQ_SAMPLE_ID_1.fastq.gz
wget -q -O - ${base_url}/STARRseq_input_lib5.2_2.fastq.gz | \
    zcat | head -n 4000 | gzip > FASTQ_SAMPLE_ID_2.fastq.gz

reference_url="ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/215/GCF_000001215.4_Release_6_plus_ISO1_MT/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna.gz"
reference_file="GENOME_PATH/GCF_000001215.4_Release_6_plus_ISO1_MT_genomic.fna"
wget -q -O - $reference_url | gunzip -c > $reference_file

# generate reference indices
# using samtools version 1.3
samtools faidx $reference_file
# using bwa version 0.7.16a-r1181
bwa index -a bwtsw $reference_file
