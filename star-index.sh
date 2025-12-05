#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem=40G
#SBATCH --output=star-index-%A.out

# exit when any command fails
set -e

if [[ -n "$CC_CLUSTER" ]]
then
  module purge
  module load StdEnv/2023
  module load samtools/1.22.1
  module load star/2.7.11b
  echo
fi

genome=
gtf=
output_dir=star
threads=${SLURM_CPUS_PER_TASK:-1}

# Usage function
usage() {
  echo
  echo "Usage: star-index.sh [-f hg38.fa] [-g hg38.gtf] [-o star] [-t int]"
  echo "  -f: FASTA file to index"
  echo "  -g: GTF file to index"
  echo "  -o: Output folder (default: star)"
  echo "  -t: Number of threads (default: 1 or SLURM_CPUS_PER_TASK if present)"
  echo "  -h: Show this help"
}

# Parsing arguments.
while getopts 'f:g:o:t:h' OPTION; do
  case "$OPTION" in
    f)
       genome="$OPTARG"
       ;;
    g)
       gtf="$OPTARG"
       ;;
    o)
       output_dir="$OPTARG"
       ;;
    t)
       threads="$OPTARG"
       ;;
    h)
       usage
       exit 0
       ;;
    :)
       usage
       exit 1
       ;;
    ?)
       usage
       exit 1
       ;;
  esac
done

# Validating arguments.
if ! [[ -f "$genome" ]]
then
  >&2 echo "Error: -f file parameter '$genome' does not exists."
  usage
  exit 1
fi
if ! [[ -f "$gtf" ]]
then
  >&2 echo "Error: -g file parameter '$gtf' does not exists."
  usage
  exit 1
fi


echo "Creating STAR index for genome $genome"
mkdir -p "$output_dir"
samtools faidx -o "${output_dir}/${genome}.fai" "$genome"
num_bases=$(awk '{sum = sum + $2}
    END{if ((log(sum)/log(2))/2 - 1 > 14) {printf "%.0f", 14}
    else {printf "%.0f", (log(sum)/log(2))/2 - 1}}' \
    "${output_dir}/${genome}.fai")

STAR \
    --runMode genomeGenerate \
    --genomeDir "$output_dir" \
    --genomeFastaFiles "$genome" \
    --sjdbGTFfile "$gtf" \
    --runThreadN "$threads" \
    --genomeSAindexNbases "$num_bases"
