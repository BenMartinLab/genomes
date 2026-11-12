#!/bin/bash

set -euo pipefail

###############################################################################
# Load modules on Alliance clusters
###############################################################################

if [[ -n "$CC_CLUSTER" ]]
then
  module purge
  module load StdEnv/2023
  module load python/3.12.4
fi
echo

###############################################################################
# Script name detection
###############################################################################

script_path=$(dirname "$(readlink -f "$0")")
cd "$script_path" || { echo "Folder $script_path does not exists"; exit 1; }
genomes_path="${script_path}/.."

###############################################################################
# Merge genomes
###############################################################################

echo "Merging human genome hg38 optimized for ribosomal DNA with fruit fly genome dm6 (BDGP6.54 release 115 from Ensembl)"

mkdir -p hg38-spike-dm6-ribosomal-dna
rm -rf hg38-spike-dm6-ribosomal-dna/*
cd hg38-spike-dm6-ribosomal-dna/

cp "${genomes_path}/human/hg38-ribosomal-dna/hg38.fa" .
cp "${genomes_path}/fruit_fly/dm6-ensembl-115/dm6.fa" .
sed -r -i.bak 's/(^>[^ ]*)/\1_fly/g' dm6.fa

cp "${genomes_path}/human/hg38-ribosomal-dna/hg38.gtf" .
cp "${genomes_path}/fruit_fly/dm6-ensembl-115/dm6.gtf" .
mv dm6.gtf dm6.gtf.bak
awk -F '\t' -v OFS="\t" '$0 !~ /#!/ {$1=$1"_fly"; print $0}' \
    dm6.gtf.bak \
    > dm6.gtf

cat hg38.fa \
    dm6.fa \
    > hg38-spike-dm6.fa
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    hg38-spike-dm6.fa \
    > hg38-spike-dm6.chrom.sizes
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    hg38.fa \
    > hg38.chrom.sizes
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    dm6.fa \
    > dm6.chrom.sizes

cat hg38.gtf \
    dm6.gtf \
    > hg38-spike-dm6.gtf

rm dm6.fa.bak
rm dm6.gtf.bak

###############################################################################
# Custom genome files
###############################################################################

mkdir -p slamseq
"${genomes_path}"/slamdunk-bed.sh --quiet --gtf hg38-spike-dm6.gtf --output slamseq/hg38-spike-dm6-slamdunk.bed

"${genomes_path}"/active-transcripts-gtf.sh --quiet --fasta hg38-spike-dm6.fa --gtf hg38-spike-dm6.gtf -w hg38-spike-dm6-active-transcripts.fa
