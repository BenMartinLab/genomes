#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem=12G
#SBATCH --output=bowtie2-build-%A.out

# exit when any command fails
set -e

if [[ -n "$CC_CLUSTER" ]]
then
  module purge
  module load StdEnv/2023
  module load bowtie2/2.5.4
  echo
fi

threads=${SLURM_CPUS_PER_TASK:-1}

echo "Creating bowtie2 index using parameters $*"
bowtie2-build --threads "$threads" "$@"
