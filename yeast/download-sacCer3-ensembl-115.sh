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

echo "Downloading yeast genome sacCer3 (R64-1-1 release 115 from Ensembl)"

mkdir -p sacCer3-ensembl-115
rm -rf sacCer3-ensembl-115/*
cd sacCer3-ensembl-115

wget https://ftp.ensembl.org/pub/release-115/fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz
wget https://ftp.ensembl.org/pub/release-115/gtf/saccharomyces_cerevisiae/Saccharomyces_cerevisiae.R64-1-1.115.gtf.gz
wget https://hgdownload.gi.ucsc.edu/goldenPath/sacCer3/database/chromAlias.txt.gz

echo "Decompressing files"
gunzip ./*.gz

echo "Filtering yeast FASTA file"
python "${filter_path}/filter-chromosome.py" \
  --white "${script_path}/yeast-chromosome-white-list.txt" \
  Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa \
  Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.filtered.fa
python "${replace_path}/replace-chromosome.py" --delete \
  --mapping chromAlias.txt \
  Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.filtered.fa \
  sacCer3.fa
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    sacCer3.fa \
    > sacCer3.chrom.sizes

echo "Filtering yeast GTF file"
python "${filter_path}/filter-chromosome.py" \
  --white "${script_path}/yeast-chromosome-white-list.txt" \
  Saccharomyces_cerevisiae.R64-1-1.115.gtf \
  Saccharomyces_cerevisiae.R64-1-1.115.filtered.gtf
python "${replace_path}/replace-chromosome.py" --delete \
  --mapping chromAlias.txt \
  Saccharomyces_cerevisiae.R64-1-1.115.filtered.gtf \
  sacCer3.gtf

rm Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa
rm Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.filtered.fa
rm Saccharomyces_cerevisiae.R64-1-1.115.gtf
rm Saccharomyces_cerevisiae.R64-1-1.115.filtered.gtf
rm chromAlias.txt
