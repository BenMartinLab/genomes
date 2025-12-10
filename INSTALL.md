# Installing genomes scripts on Alliance Canada

### Steps

1. [Installing of the scripts](#Installing-of-the-scripts)
    1. [Change directory to `projects` folder](#Change-directory-to-projects-folder)
    2. [Clone repository](#Clone-repository)
2. [Updating scripts](#Updating-scripts)
3. [Downloading genomes](#Downloading-genomes)
4. [Genomes with spike-in](#Genomes-with-spike-in)
5. [Creating indexes for bowtie2, STAR, etc...](#Creating-indexes-for-bowtie2-STAR-etc)
   1. [Bowtie2](#Bowtie2)
   2. [STAR](#STAR)
6. [Creating pipeline specific files](#Creating-pipeline-specific-files)
   1. [PRO-seq](#PRO-seq)
      1. [Create TSS list from GTF](#Create-TSS-list-from-GTF)
      2. [Create transcript list from GTF](#Create-transcript-list-from-GTF)
      3. [Symlink proseq folder to spike-in genomes](#Symlink-proseq-folder-to-spike-in-genomes)

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

> [!IMPORTANT]
> Change `human/hg38-ensembl-115` by the genome you want to use.

```shell
cd $genomes_folder/human/hg38-ensembl-115
```

Set genome name in a variable. It can be a genome with spike-in like `hg38-spike-dm6`.

> [!IMPORTANT]
> Change `hg38` by the genome you want to use.

```shell
genome=hg38
```

### Bowtie2

```shell
mkdir bowtie2
sbatch bowtie2-build.sh $genome.fa bowtie2/$genome
```

### STAR

> [!NOTE]
> If `star-index.sh` job fails due to memory, change the value of `--mem`.

```shell
sbatch --mem=40G star-index.sh -f $genome.fa -g $genome.gtf
```

## Creating pipeline specific files

### PRO-seq

Add PRO-seq scripts folder to your PATH.

```shell
export PATH=~/projects/def-bmartin/scripts/proseq:$PATH
```

For Rorqual server, use

```shell
export PATH=~/links/projects/def-bmartin/scripts/proseq:$PATH
```

Move to desired genome.

> [!IMPORTANT]
> Change `human/hg38-ensembl-115` by the genome you want to use.

```shell
cd $genomes_folder/human/hg38-ensembl-115
```

Set genome name in a variable. It can be a genome with spike-in like `hg38-spike-dm6`.

> [!IMPORTANT]
> Change `hg38` by the genome you want to use.

```shell
genome=hg38
```

Create sub-folder for PRO-seq specific files.

```shell
mkdir -p proseq
```

#### Create TSS list from GTF

```shell
rm -f proseq/$genome.gtf
awk '$0 !~ /#!/' $genome.gtf > "proseq/${genome}.gtf"
create-tss-list.sh -g "proseq/${genome}.gtf"
```

If the `create-tss-list.sh` command fails due to memory usage, you can run it using `sbatch`.

```shell
sbatch create-tss-list.sh -g "proseq/${genome}.gtf"
```

#### Create transcript list from GTF

```shell
create-transcript-list.sh \
    -g $genome.gtf \
    -f transcript \
    -s transcript_id \
    -t gene_name \
    -d proseq \
    -a gene_biotype
```

If the `create-transcript-list.sh` command fails due to memory usage, you can run it using `sbatch`.

```shell
sbatch create-transcript-list.sh \
    -g $genome.gtf \
    -f transcript \
    -s transcript_id \
    -t gene_name \
    -d proseq \
    -a gene_biotype
```
