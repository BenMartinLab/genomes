#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --output=transcript-bed-%A.out

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
    echo
    echo "Usage: $script_name [options]"
    echo
    echo "Wrapper options:"
    echo "  -g, --gtf       FILE       GTF file (required)"
    echo "  -o, --output    FILE       Output file (required)"
    echo "  -d, --dry-run              Print commands but do not execute"
    echo "  -q, --quiet                Don't show messages"
    echo "  -h, --help                 Show this help"
    echo
    echo "Example:"
    echo "  sbatch $script_name --gtf hg38.gtf --output hg38-transcripts.bed"
    echo "  $script_name --gtf hg38.gtf --output hg38-transcripts.bed"
    echo
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
        -g|--gtf)
            gtf="$2"
            shift 2
            ;;
        --gtf=*)
            gtf="${1#--gtf=}"
            shift
            ;;
        -o|--output)
            output="$2"
            shift 2
            ;;
        --output=*)
            output="${1#--output=}"
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

if [[ ! -f "${gtf:-}" ]]; then
    echo "Error: GTF '${gtf:-}' does not exist." >&2
    exit 1
fi
if [[ -z "${output:-}" ]]; then
    echo "Error: Output file is required." >&2
    exit 1
fi

###############################################################################
# Logging + SLURM metadata + environment dump
###############################################################################

if [[ "${quiet:-}" == "false" ]]; then
    echo "------------------------------------------------------------"
    echo "$script_name started at: $(date)"
    echo "Host: $(hostname)"
    echo "User: $USER"
    echo "Script: $script_name"
    echo
    echo "SLURM metadata:"
    echo "  Job ID:        ${SLURM_JOB_ID:-N/A}"
    echo "  Array Task ID: ${SLURM_ARRAY_TASK_ID:-N/A}"
    echo "  CPUs:          ${SLURM_CPUS_PER_TASK:-N/A}"
    echo "  Node:          ${SLURM_NODELIST:-N/A}"
    echo
    if [[ "${debug:-}" == true ]]; then
        echo "Environment dump:"
        env | sort
    fi
    echo "------------------------------------------------------------"
    echo
    echo "GTF:         $gtf"
    echo "Output:      $output"
    echo "Dry-run:     $dry_run"
    echo
fi


###############################################################################
# Build command
###############################################################################

# shellcheck disable=SC2016
cmd1=(
    awk -F '\t' -v OFS='\t'
    '$3 ~ /.*RNA/ || $3 == "pseudogene"'
    "$gtf"
)
# shellcheck disable=SC2016
cmd2=(
    awk -F '\t' -v OFS='\t'
    '{transcript_id=gensub(/.*transcript_id "([a-zA-Z0-9_\-\(\)]+)".*/,"\\1","1",$9);
                print $1,$4,$5,transcript_id,0,$7}'
)

if [[ "$dry_run" == true ]] || [[ "${quiet:-}" == "false" ]]; then
  echo "Command:"
  printf " %q " "${cmd1[@]}"
  printf " | "
  printf " %q " "${cmd2[@]}"
  printf " > "
  printf " %q " "$output"
  echo
  echo
fi

###############################################################################
# Execute command
###############################################################################

if [[ "$dry_run" == true ]]; then
    echo "Dry-run mode enabled — command not executed."
    exit 0
fi

"${cmd1[@]}" | "${cmd2[@]}" > "$output"
