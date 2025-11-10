# Installing genomes scripts on Alliance Canada

### Steps

1. [Updating scripts](#Updating-scripts)
2. [Installing of the scripts](#Installing-of-the-scripts)
    1. [Change directory to `projects` folder](#Change-directory-to-projects-folder)
    2. [Clone repository](#Clone-repository)
3. [Downloading genomes](#Downloading-genomes)
4. [Genomes with spike-in](#Genomes-with-spike-in)

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
cd ~/projects/def-bmartin/scripts
```

For Rorqual server, use

```shell
cd ~/links/projects/def-bmartin/scripts
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
