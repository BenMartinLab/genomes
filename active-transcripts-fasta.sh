#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --output=active-transcripts-fasta-%A.out

set -euo pipefail

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
Usage: $script_name [options] -- [extra args passed to gffread]

Options:
  -f, --fasta     FILE       FASTA file of genome (required)
  -g, --gtf       FILE       GTF file (required)
  -d, --dry-run              Print commands but do not execute
  -q, --quiet                Don't show messages
  -h, --help                 Show this help

Everything after '--' or any unknown option is passed directly to gffread.

Example:
  sbatch $script_name --fasta hg38.fa --gtf hg38.gtf -w hg38-active-transcripts.gtf
  $script_name --fasta hg38.fa --gtf hg38.gtf -w hg38-active-transcripts.gtf

END_OF_HELP
}

###############################################################################
# Default values
###############################################################################

dry_run=false
quiet=false

###############################################################################
# Manual argument parsing (safe, collision-free)
###############################################################################

extra_parameters=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--fasta)
            fasta="$2"
            shift 2
            ;;
        --fasta=*)
            fasta="${1#--fasta=}"
            shift
            ;;
        -g|--gtf)
            gtf="$2"
            shift 2
            ;;
        --gtf=*)
            gtf="${1#--gtf=}"
            shift
            ;;
        -d|--dry-run)
            dry_run=true
            shift
            ;;
        -q|--quiet)
            quiet=true
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

if [[ ! -f "${fasta:-}" ]]; then
    echo "Error: FASTA '${fasta:-}' does not exist." >&2
    exit 1
fi
if [[ ! -f "${gtf:-}" ]]; then
    echo "Error: GTF '${gtf:-}' does not exist." >&2
    exit 1
fi

###############################################################################
# Logging + SLURM metadata + environment dump
###############################################################################

if [[ "${quiet:-}" == "false" ]]; then
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

FASTA:       $fasta
GTF:         $gtf
Dry-run:     $dry_run
Quiet:       $quiet


END_OF_PARAMETER_LOG
fi

###############################################################################
# Build command
###############################################################################

# shellcheck disable=SC2016
cmd1=(
    awk -F '\t' -v OFS='\t'
    '{
        gene_biotype=gensub(/.*gene_biotype "([a-zA-Z0-9_\-\(\)]+)".*/,"\\1","1",$9);
        transcript_support_level=gensub(/.*transcript_support_level "([a-zA-Z0-9_\-\(\)]+)".*/,"\\1","1",$9);

        # Skip gene type.
        if ($3 == "gene") {
            next;
        }
        # Use only protein_coding (mRNA), snRNA or non-suspect transcripts.
        if (gene_biotype == "protein_coding" || gene_biotype == "snRNA" ||
              (transcript_support_level ~ /[0-9]+/ && transcript_support_level < 4)) {
           print $0
        }
    }'
    "$gtf"
)
cmd2=(
    gffread
    -g "$fasta"
    "${extra_parameters[@]}"
)

###############################################################################
# Execute command
###############################################################################

if [[ "$dry_run" == true ]] || [[ "${quiet:-}" == "false" ]]; then
  echo "Command:"
  printf " %q " "${cmd1[@]}"
  printf " | "
  printf " %q " "${cmd2[@]}"
  echo
  echo
fi

if [[ "$dry_run" == true ]]; then
    echo "Dry-run mode enabled — command not executed."
    exit 0
fi

"${cmd1[@]}" | "${cmd2[@]}"
