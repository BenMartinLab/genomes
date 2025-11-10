# Genomes

This repository contains scripts to use genomes on Alliance Canada servers.

To install the scripts on Alliance Canada servers and download genomes, see [INSTALL.md](INSTALL.md)

### Steps

1. [Finding desired genome](#Finding-desired-genome)
2. [Copying genome to scratch](#Copying-genome-to-scratch)

## Finding desired genome

First, set the location of the genomes scripts.

```shell
genomes_folder=~/projects/def-bmartin/genomes
```

For Rorqual server, use

```shell
genomes_folder=~/links/projects/def-bmartin/genomes
```

Then, locate the genome that you want. A good command is to use `ls` to find the desired main genome.

```shell
ls $genomes_folder
```

For example, if you want a human genome, you can look at the `human` sub-folder.

```shell
ls $genomes_folder/human
```

Assuming, you want the Ensembl release version 115 of the human genome, the folder containing the genome will be.

```shell
ls $genomes_folder/human/hg38-ensembl-115
```

## Copying genome to scratch

Once you have located the genome that you wish to use, I recommend to copy it to the scratch folder along other files like FASTQ.

Assuming you wish to use the human genome from Ensembl release version 115, use the following command from the same folder containing other files like FASTQ.

```shell
cp $genomes_folder/human/hg38-ensembl-115/* .
```

If you see an error like `cp: cannot stat '/human/hg38-ensembl-115': No such file or directory`, it means the variable `genomes_folder` is not defined.
To set the variable, see [Finding desired genome](#Finding-desired-genome)
