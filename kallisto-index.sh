#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem=12G
#SBATCH --output=kallisto-index-%A.out

set -euo pipefail

###############################################################################
# Load modules on Alliance clusters
###############################################################################

if [[ -n "${CC_CLUSTER:-}" ]]; then
    module purge
    module load StdEnv/2023
    module load kallisto/0.51.1
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
    echo
    echo "Usage: $script_name [options] -- [extra args passed to kallisto index]"
    echo
    echo "Wrapper options:"
    echo "  -t, --threads    INT       Threads (default: SLURM_CPUS_PER_TASK)"
    echo "  -T, --tmp        DIR       Temporary directory (default: SLURM_TMPDIR)"
    echo "  -d, --dry-run              Print commands but do not execute"
    echo "  -h, --help                 Show this help"
    echo
    echo "Everything after '--' or any unknown option is passed directly to kallisto index."
    echo
    echo "Do not specify FASTQ files; they are inferred from the samplesheet."
    echo
    echo "Example:"
    echo "  sbatch --cpus-per-task=8 $script_name --samplesheet samples.csv -i kallisto/human.idx -x BULK --paired"
    echo "  $script_name --samplesheet samples.csv -i kallisto/human.idx -x BULK --paired"
    echo
}

###############################################################################
# Default values
###############################################################################

threads="${SLURM_CPUS_PER_TASK:-1}"
tmp_dir=${SLURM_TMPDIR:-}
dry_run=false

###############################################################################
# Manual argument parsing (safe, collision-free)
###############################################################################

extra_parameters=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--threads)
            threads="$2"
            shift 2
            ;;
        --threads=*)
            threads="${1#--threads=}"
            shift
            ;;
        -T|--tmp)
            tmp_dir="$2"
            shift 2
            ;;
        --tmp=*)
            tmp_dir="${1#--tmp_dir=}"
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
        --*=*)
            # Long option with equals: --option=value
            extra_parameters+=("$1")
            shift
            ;;
        -*)
            # Unknown short option → passthrough to kallisto
            extra_parameters+=("$1")
            shift
            ;;
        *)
            # Positional argument → passthrough
            extra_parameters+=("$1")
            shift
            ;;
    esac
done

###############################################################################
# Use outTmpDir parameter only if specified or if SLURM is used, otherwise use kallisto default value.
###############################################################################

if [[ -n "$tmp_dir" ]]
then
  extra_parameters=("-T" "$tmp_dir" "${extra_parameters[@]}")
fi

###############################################################################
# Logging + SLURM metadata + environment dump
###############################################################################

echo "------------------------------------------------------------"
echo "kallisto-index.sh started at: $(date)"
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
echo "Environment dump:"
env | sort
echo "------------------------------------------------------------"
echo

###############################################################################
# Build kallisto command
###############################################################################

cmd=(
    kallisto index
    --threads="$threads"
    "${extra_parameters[@]}"
)

###############################################################################
# Dry-run mode
###############################################################################

echo "Threads:     $threads"
echo "Tmp dir:     $tmp_dir"
echo "Dry-run:     $dry_run"
echo
echo "Command:"
printf "  %q " "${cmd[@]}"
echo
echo

if [[ "$dry_run" == true ]]; then
    echo "Dry-run mode enabled — command not executed."
    exit 0
fi

###############################################################################
# Execute kallisto
###############################################################################

"${cmd[@]}"
