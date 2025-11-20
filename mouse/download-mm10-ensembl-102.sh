#!/bin/bash

# exit when any command fails
set -e

if [[ -n "$CC_CLUSTER" ]]
then
  module purge
  module load StdEnv/2023
  module load python/3.12.4
fi
echo

script_path=$(dirname "$(readlink -f "$0")")
cd "$script_path" || { echo "Folder $script_path does not exists"; exit 1; }
filter_path="${script_path}/.."
replace_path="${script_path}/.."

echo "Downloading mouse genome mm10 (GRCm38.p6 release 102 from Ensembl)"

mkdir -p mm10-ensembl-102
rm -rf mm10-ensembl-102/*
cd mm10-ensembl-102

wget ftp://ftp.ensembl.org/pub/release-102/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz
wget ftp://ftp.ensembl.org/pub/release-102/gtf/mus_musculus/Mus_musculus.GRCm38.102.gtf.gz
wget https://hgdownload.gi.ucsc.edu/goldenPath/mm10/database/chromAlias.txt.gz

echo "Decompressing files"
gunzip ./*.gz

echo "Filtering mouse FASTA file"
python "${filter_path}/filter-chromosome.py" \
  --white "${script_path}/mouse-chromosome-white-list.txt" \
  Mus_musculus.GRCm38.dna.primary_assembly.fa \
  Mus_musculus.GRCm38.dna.primary_assembly.filtered.fa
python "${replace_path}/replace-chromosome.py" --delete \
  --mapping chromAlias.txt \
  Mus_musculus.GRCm38.dna.primary_assembly.filtered.fa \
  mm10.fa
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    mm10.fa \
    > mm10.chrom.sizes

echo "Filtering mouse GTF file"
python "${filter_path}/filter-chromosome.py" \
  --white "${script_path}/mouse-chromosome-white-list.txt" \
  Mus_musculus.GRCm38.102.gtf \
  Mus_musculus.GRCm38.102.filtered.gtf
python "${replace_path}/replace-chromosome.py" --delete \
  --mapping chromAlias.txt \
  Mus_musculus.GRCm38.102.filtered.gtf \
  mm10.gtf

rm Mus_musculus.GRCm38.dna.primary_assembly.fa
rm Mus_musculus.GRCm38.dna.primary_assembly.filtered.fa
rm Mus_musculus.GRCm38.102.gtf
rm Mus_musculus.GRCm38.102.filtered.gtf
rm chromAlias.txt
