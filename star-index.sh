#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem=40G
#SBATCH --output=star-index-%A.out

set -euo pipefail

###############################################################################
# Load modules on Alliance clusters
###############################################################################

if [[ -n "${CC_CLUSTER:-}" ]]; then
    module purge
    module load StdEnv/2023
    module load samtools/1.22.1
    module load star/2.7.11b
    echo
fi

###############################################################################
# Script name detection (SLURM-friendly)
###############################################################################

script_path="${BASH_SOURCE[0]}"
if [[ "$(basename "$script_path")" == "slurm_script" && -n "${SLURM_JOB_ID:-}" ]]; then
    script_path="$(scontrol show job "$SLURM_JOB_ID" \
        | awk -F= '/Command=/ {print $2; exit}')"
fi
script_name="$(basename "$script_path")"

###############################################################################
# Help text
###############################################################################

show_help() {
    cat << END_OF_HELP
Usage: $script_name [options] -- [extra args passed to STAR]

Wrapper options:
  -g, --genomeFastaFiles FILE  FASTA file to index (required)
  --genomeSAindexNbases  INT   length of the SA pre-indexing string (default: computed base on genome)
  -t, --threads          INT   Threads (default: SLURM_CPUS_PER_TASK)
  -d, --dry-run                Print commands but do not execute
  -h, --help                   Show this help

Everything after '--' or any unknown option is passed directly to STAR.

Example:
  sbatch --cpus-per-task=8 $script_name hg38.fa bowtie2/hg38
  $script_name --threads 8 hg38.fa bowtie2/hg38

END_OF_HELP
}

###############################################################################
# Default values
###############################################################################

threads="${SLURM_CPUS_PER_TASK:-1}"
dry_run=false

###############################################################################
# Manual argument parsing (safe, collision-free)
###############################################################################

extra_parameters=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--genomeFastaFiles)
            genome="$2"
            shift 2
            ;;
        --genomeFastaFiles=*)
            genome="${1#--genomeFastaFiles=}"
            shift
            ;;
        --genomeSAindexNbases)
            num_bases="$2"
            shift 2
            ;;
        --genomeSAindexNbases=*)
            num_bases="${1#--genomeSAindexNbases=}"
            shift
            ;;
        -t|--threads)
            threads="$2"
            shift 2
            ;;
        --threads=*)
            threads="${1#--threads=}"
            shift
            ;;
        -d|--dry-run)
            dry_run=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --)
            shift
            extra_parameters+=("$@")
            break
            ;;
        *)
            # Unknown argument → passthrough
            extra_parameters+=("$1")
            shift
            ;;
    esac
done

###############################################################################
# Validate arguments
###############################################################################

if ! [[ -f "${genome:-}" ]]; then
    echo "Error: Genome '${genome:-}' does not exist." >&2
    exit 1
fi

###############################################################################
# Compute value of `--genomeSAindexNbases` argument for STAR
###############################################################################

if [[ -z "${num_bases:-}" ]]; then
  genome_fai=$(samtools faidx -o - "$genome")
  num_bases=$(awk '{sum = sum + $2}
      END{if ((log(sum)/log(2))/2 - 1 > 14) {print 14}
      else {print int((log(sum)/log(2))/2 - 1)}}' \
      <<< "$genome_fai")
fi

###############################################################################
# Logging + SLURM metadata + environment dump
###############################################################################

cat << END_OF_SLURM_LOG
------------------------------------------------------------
$script_name started at: $(date)
Host: $(hostname)
User: $USER
Script: $script_name

SLURM metadata:
  Job ID:        ${SLURM_JOB_ID:-N/A}
  Array Task ID: ${SLURM_ARRAY_TASK_ID:-N/A}
  CPUs:          ${SLURM_CPUS_PER_TASK:-N/A}
  Node:          ${SLURM_NODELIST:-N/A}
END_OF_SLURM_LOG
if [[ ${debug:-} == true ]]; then
    echo "Environment dump:"
    env | sort
fi
cat << END_OF_PARAMETER_LOG
------------------------------------------------------------

Genome:      $genome
Nbases:      $num_bases
Threads:     $threads
Dry-run:     $dry_run


END_OF_PARAMETER_LOG

###############################################################################
# Build command
###############################################################################

cmd=(
    STAR
    --runMode genomeGenerate
    --genomeFastaFiles "$genome"
    --genomeSAindexNbases "$num_bases"
    --runThreadN "$threads"
    "${extra_parameters[@]}"
)

###############################################################################
# Execute command
###############################################################################

echo "Command:"
printf "  %q " "${cmd[@]}"
echo
echo

if [[ "$dry_run" == true ]]; then
    echo "Dry-run mode enabled — command not executed."
    exit 0
fi

"${cmd[@]}"
