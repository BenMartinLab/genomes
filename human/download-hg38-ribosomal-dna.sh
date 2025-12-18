#!/bin/bash

# exit when any command fails
set -e

if [[ -n "$CC_CLUSTER" ]]
then
  module purge
  module load StdEnv/2023
  module load python/3.12.4
  module load kent_tools/486
fi
echo

script_path=$(dirname "$(readlink -f "$0")")
cd "$script_path" || { echo "Folder $script_path does not exists"; exit 1; }
filter_path="${script_path}/.."
replace_path="${script_path}/.."

echo "Downloading human genome hg38 optimized for ribosomal DNA (https://github.com/vikramparalkar/rDNA-Mapping-Genomes)"

mkdir -p hg38-ribosomal-dna
rm -rf hg38-ribosomal-dna/*
cd hg38-ribosomal-dna

wget https://media.githubusercontent.com/media/vikramparalkar/rDNA-Mapping-Genomes/refs/heads/main/Human_hg38-rDNA_genome_v1.0.tar.gz
wget https://media.githubusercontent.com/media/vikramparalkar/rDNA-Mapping-Genomes/refs/heads/main/Human_hg38-rDNA_genome_v1.0_annotation.tar.gz
wget https://ftp.ensembl.org/pub/release-115/gtf/homo_sapiens/Homo_sapiens.GRCh38.115.gtf.gz
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/chromAlias.txt.gz

echo "Decompressing files"
tar -xvf Human_hg38-rDNA_genome_v1.0.tar.gz
tar -xvf Human_hg38-rDNA_genome_v1.0_annotation.tar.gz
gunzip Homo_sapiens.GRCh38.115.gtf.gz
gunzip chromAlias.txt.gz

echo "Filtering human FASTA file"
python "${filter_path}/filter-chromosome.py" \
  --white "${script_path}/human-chromosome-white-list.txt" \
  Human_hg38-rDNA_genome_v1.0/hg38-rDNA_v1.0.fa \
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
  hg38-nonR.gtf
bedToGenePred Human_hg38-rDNA_genome_v1.0_annotation/hg38-rDNA_v1.0.bed /dev/stdout \
    | grep chrR \
    | genePredToGtf file /dev/stdin Human_hg38-rDNA_genome_v1.0_annotation/hg38-rDNA_v1.0.gtf
cat hg38-nonR.gtf Human_hg38-rDNA_genome_v1.0_annotation/hg38-rDNA_v1.0.gtf \
    > hg38.gtf

rm Human_hg38-rDNA_genome_v1.0.tar.gz
rm Human_hg38-rDNA_genome_v1.0_annotation.tar.gz
rm -r Human_hg38-rDNA_genome_v1.0
rm -r Human_hg38-rDNA_genome_v1.0_annotation
rm Homo_sapiens.GRCh38.115.gtf
rm Homo_sapiens.GRCh38.115.filtered.gtf
rm hg38-nonR.gtf
rm chromAlias.txt
