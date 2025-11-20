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

echo "Downloading fruit fly genome dm6 (BDGP6.28 release 102 from Ensembl)"

mkdir -p dm6-ensembl-102
rm -rf dm6-ensembl-102/*
cd dm6-ensembl-102

wget ftp://ftp.ensembl.org/pub/release-102/fasta/drosophila_melanogaster/dna/Drosophila_melanogaster.BDGP6.28.dna.toplevel.fa.gz
wget ftp://ftp.ensembl.org/pub/release-102/gtf/drosophila_melanogaster/Drosophila_melanogaster.BDGP6.28.102.gtf.gz
wget https://hgdownload.gi.ucsc.edu/goldenPath/dm6/database/chromAlias.txt.gz

echo "Decompressing files"
gunzip ./*.gz

echo "Filtering fruit fly FASTA file"
sed -i.bak '1s/^/mitochondrion_genome\tchrM\tensembl\n/' chromAlias.txt
python "${filter_path}/filter-chromosome.py" \
  --white "${script_path}/fruit-fly-chromosome-white-list.txt" \
  Drosophila_melanogaster.BDGP6.28.dna.toplevel.fa \
  Drosophila_melanogaster.BDGP6.28.dna.toplevel.filtered.fa
python "${replace_path}/replace-chromosome.py" --delete \
  --mapping chromAlias.txt \
  Drosophila_melanogaster.BDGP6.28.dna.toplevel.filtered.fa \
  dm6.fa
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    dm6.fa \
    > dm6.chrom.sizes

echo "Filtering fruit fly GTF file"
python "${filter_path}/filter-chromosome.py" \
  --white "${script_path}/fruit-fly-chromosome-white-list.txt" \
  Drosophila_melanogaster.BDGP6.28.102.gtf \
  Drosophila_melanogaster.BDGP6.28.102.filtered.gtf
python "${replace_path}/replace-chromosome.py" --delete \
  --mapping chromAlias.txt \
  Drosophila_melanogaster.BDGP6.28.102.filtered.gtf \
  dm6.gtf

rm Drosophila_melanogaster.BDGP6.28.dna.toplevel.fa
rm Drosophila_melanogaster.BDGP6.28.dna.toplevel.filtered.fa
rm Drosophila_melanogaster.BDGP6.28.102.gtf
rm Drosophila_melanogaster.BDGP6.28.102.filtered.gtf
rm chromAlias.txt
rm chromAlias.txt.bak
