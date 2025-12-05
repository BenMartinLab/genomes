# Installing genomes scripts on Alliance Canada

### Steps

1. [Updating scripts](#Updating-scripts)
2. [Installing of the scripts](#Installing-of-the-scripts)
   1. [Change directory to `projects` folder](#Change-directory-to-projects-folder)
   2. [Clone repository](#Clone-repository)
3. [Downloading genomes](#Downloading-genomes)
4. [Genomes with spike-in](#Genomes-with-spike-in)
5. [Creating indexes for bowtie2, STAR, etc...](#Creating-indexes-for-bowtie2-STAR-etc)
   1. [Bowtie2](#Bowtie2)
   2. [STAR](#STAR)

## Updating scripts

Go to the genomes scripts folder and run `git pull`.

```shell
cd ~/projects/def-bmartin/genomes
git pull
```

For Rorqual server, use

```shell
cd ~/links/projects/def-bmartin/genomes
git pull
```

## Installing of the scripts

### Change directory to projects folder

```shell
cd ~/projects/def-bmartin
```

For Rorqual server, use

```shell
cd ~/links/projects/def-bmartin
```

### Clone repository

```shell
git clone https://github.com/BenMartinLab/genomes.git
```

## Downloading genomes

First, set the location of the genomes scripts.

```shell
genomes_folder=~/projects/def-bmartin/genomes
```

For Rorqual server, use

```shell
genomes_folder=~/links/projects/def-bmartin/genomes
```

Then, run the desired download script. For example:

```shell
bash $genomes_folder/human/download-hg38-ensembl-115.sh
```

## Genomes with spike-in

First, check that the individual genomes are already downloaded.

Then, run the desired script. For example:

```shell
bash $genomes_folder/human/create-hg38-spike-dm6-ensembl-115.sh
```

## Creating indexes for bowtie2, STAR, etc...

Add genomes scripts folder to your PATH.

```shell
export PATH=~/projects/def-bmartin/genomes:$PATH
```

For Rorqual server, use

```shell
export PATH=~/links/projects/def-bmartin/genomes:$PATH
```

Move to the desired genome.

```shell
cd $genomes_folder/human/hg38-ensembl-115
```

### Bowtie2

```shell
mkdir bowtie2
sbatch bowtie2-build.sh hg38.fa bowtie2/hg38
```

### STAR

> [!NOTE]
> If `star-index.sh` job fails due to memory, change the value of `--mem`.

```shell
sbatch --mem=40G star-index.sh -f hg38.fa -g hg38.gtf
```
