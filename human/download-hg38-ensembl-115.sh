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

echo "Downloading human genome hg38 (GRCh38.p14 release 115 from Ensembl)"

mkdir -p hg38-ensembl-115
rm -rf hg38-ensembl-115/*
cd hg38-ensembl-115

wget https://ftp.ensembl.org/pub/release-115/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz
wget https://ftp.ensembl.org/pub/release-115/gtf/homo_sapiens/Homo_sapiens.GRCh38.115.gtf.gz
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/chromAlias.txt.gz

echo "Decompressing files"
gunzip ./*.gz

echo "Filtering human FASTA file"
python "${filter_path}/filter-chromosome.py" \
  --white "${script_path}/human-chromosome-white-list.txt" \
  Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa \
  Homo_sapiens.GRCh38.dna_sm.primary_assembly.filtered.fa
python "${replace_path}/replace-chromosome.py" --delete \
  --mapping chromAlias.txt \
  Homo_sapiens.GRCh38.dna_sm.primary_assembly.filtered.fa \
  hg38.fa
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    hg38.fa \
    > hg38.chrom.sizes

echo "Filtering human GTF file"
python "${filter_path}/filter-chromosome.py" \
  --white "${script_path}/human-chromosome-white-list.txt" \
  Homo_sapiens.GRCh38.115.gtf \
  Homo_sapiens.GRCh38.115.filtered.gtf
python "${replace_path}/replace-chromosome.py" --delete \
  --mapping chromAlias.txt \
  Homo_sapiens.GRCh38.115.filtered.gtf \
  hg38.gtf

rm Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa
rm Homo_sapiens.GRCh38.dna_sm.primary_assembly.filtered.fa
rm Homo_sapiens.GRCh38.115.gtf
rm Homo_sapiens.GRCh38.115.filtered.gtf
rm chromAlias.txt
