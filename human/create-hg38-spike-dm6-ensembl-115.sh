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

echo "Merging human genome hg38 (GRCh38.p14 release 115 from Ensembl) with fruit fly genome dm6 (BDGP6.54 release 115 from Ensembl)"

mkdir -p hg38-spike-dm6-ensembl-115
rm -rf hg38-spike-dm6-ensembl-115/*
cd hg38-spike-dm6-ensembl-115/

cp "${script_path}/../fruit_fly/dm6-ensembl-115/dm6.fa" .
sed -r -i.bak 's/(^>[^ ]*)/\1_fly/g' dm6.fa

cp "${script_path}/../fruit_fly/dm6-ensembl-115/dm6.gtf" .
mv dm6.gtf dm6.gtf.bak
awk -F '\t' -v OFS="\t" '$0 !~ /#!/ {$1=$1"_fly"; print $0}' \
    dm6.gtf.bak \
    > dm6.gtf

cat "${script_path}/hg38-ensembl-115/hg38.fa" \
    dm6.fa \
    > hg38-spike-dm6.fa
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    hg38-spike-dm6.fa \
    > hg38-spike-dm6.chrom.sizes

cat "${script_path}/hg38-ensembl-115/hg38.gtf" \
    dm6.gtf \
    > hg38-spike-dm6.gtf

rm dm6.fa.bak
rm dm6.gtf.bak
