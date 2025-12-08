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

echo "Merging mouse genome mm10 (GRCm38.p6 release 102 from Ensembl) with fruit fly genome dm6 (BDGP6.28 release 102 from Ensembl)"

mkdir -p mm10-spike-dm6-ensembl-102
rm -rf mm10-spike-dm6-ensembl-102/*
cd mm10-spike-dm6-ensembl-102/

cp "${script_path}/../mouse/mm10-ensembl-102/mm10.fa" .
cp "${script_path}/../fruit_fly/dm6-ensembl-102/dm6.fa" .
sed -r -i.bak 's/(^>[^ ]*)/\1_fly/g' dm6.fa

cp "${script_path}/../mouse/mm10-ensembl-102/mm10.gtf" .
cp "${script_path}/../fruit_fly/dm6-ensembl-102/dm6.gtf" .
mv dm6.gtf dm6.gtf.bak
awk -F '\t' -v OFS="\t" '$0 !~ /#!/ {$1=$1"_fly"; print $0}' \
    dm6.gtf.bak \
    > dm6.gtf

cat mm10.fa \
    dm6.fa \
    > mm10-spike-dm6.fa
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    mm10-spike-dm6.fa \
    > mm10-spike-dm6.chrom.sizes
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    mm10.fa \
    > mm10.chrom.sizes
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    dm6.fa \
    > dm6.chrom.sizes

cat mm10.gtf \
    dm6.gtf \
    > mm10-spike-dm6.gtf

rm dm6.fa.bak
rm dm6.gtf.bak
