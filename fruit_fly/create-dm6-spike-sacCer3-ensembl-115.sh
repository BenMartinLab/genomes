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

echo "Merging fruit fly genome dm6 (BDGP6.54 release 115 from Ensembl) with yeast genome sacCer3 (R64-1-1 release 115 from Ensembl)"

mkdir -p dm6-spike-sacCer3-ensembl-115
rm -rf dm6-spike-sacCer3-ensembl-115/*
cd dm6-spike-sacCer3-ensembl-115/

cp "${script_path}/../fruit_fly/dm6-ensembl-115/dm6.fa" .
cp "${script_path}/../yeast/sacCer3-ensembl-115/sacCer3.fa" .
sed -r -i.bak 's/(^>[^ ]*)/\1_yeast/g' sacCer3.fa

cp "${script_path}/../fruit_fly/dm6-ensembl-115/dm6.gtf" .
cp "${script_path}/../yeast/sacCer3-ensembl-115/sacCer3.gtf" .
mv sacCer3.gtf sacCer3.gtf.bak
awk -F '\t' -v OFS="\t" '$0 !~ /#!/ {$1=$1"_yeast"; print $0}' \
    sacCer3.gtf.bak \
    > sacCer3.gtf

cat dm6.fa \
    sacCer3.fa \
    > dm6-spike-sacCer3.fa
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    dm6-spike-sacCer3.fa \
    > dm6-spike-sacCer3.chrom.sizes
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    dm6.fa \
    > dm6.chrom.sizes
awk '$0 ~ ">" {if (NR > 1) {print c;} c=0;printf substr($1,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
    sacCer3.fa \
    > sacCer3.chrom.sizes

cat dm6.gtf \
    sacCer3.gtf \
    > dm6-spike-sacCer3.gtf

rm sacCer3.fa.bak
rm sacCer3.gtf.bak
