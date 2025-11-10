#!/usr/bin/env python3

import argparse
import re
import sys
from typing import TextIO
from collections.abc import Callable


def main(argv: list[str] = None):
    parser = argparse.ArgumentParser(description="Filters chromosomes and other annotations present in input file.")
    parser.add_argument('input', nargs='?', type=argparse.FileType('r'), default=sys.stdin,
                        help="Input file with chromosomes to filter")
    parser.add_argument('output', nargs='?', type=argparse.FileType('w'), default=sys.stdout,
                        help="Output file with chromosomes filtered")
    parser.add_argument('-f', '--format', choices = ['fasta', 'gff'], default=None,
                        help="Input file format  (default: type is guessed using filename extension)")
    parser.add_argument('-w', '--white', type=argparse.FileType('r'), required=True,
                        help="Text file containing a white list of chromosome " +
                             "(only the chromosomes present in white list will be kept).")

    args = parser.parse_args(argv)
    filter_chromosome_white_list(input_file=args.input, output_file=args.output, white_list_file=args.white)


def filter_chromosome_white_list(input_file: TextIO, output_file: TextIO, white_list_file: TextIO,
    input_format: str = None):
    """
    Filters chromosomes in input file using white list file.

    :param input_file: input file with chromosomes to convert
    :param output_file: output file with chromosomes replaced
    :param white_list_file: text file containing a white list of chromosome
    :param input_format: input file format  (default: type is guessed using filename extension)
    """
    if not input_format:
        try:
            filename = input_file.name.lower()
            if filename.endswith(".fasta") or filename.endswith(".fa") or filename.endswith(".fna"):
                input_format = "fasta"
            elif filename.endswith(".gff") or filename.endswith(".gtf"):
                input_format = "gff"
        except AttributeError:
            print(f"Input is not a file and no format parameter was given", file=sys.stderr)

    while_list = parse_chromosome_list(white_list_file)
    while_list_function = lambda chromosome: chromosome in while_list

    if input_format == "fasta":
        filter_chromosomes_fasta(input_file=input_file, output_file=output_file, filter_function=while_list_function)
    elif input_format == "gff":
        filter_chromosomes_gff(input_file=input_file, output_file=output_file, filter_function=while_list_function)
    else:
        print(f"File format {input_format} not implemented yet.", file=sys.stderr)


def filter_chromosomes_fasta(input_file: TextIO, output_file: TextIO, filter_function: Callable[[str], bool]):
    """
    Converts chromosomes in input FASTA file.

    :param input_file: FASTA file with chromosomes to convert
    :param output_file: output FASTA file with chromosomes replaced
    :param filter_function: function that should return true if chromosome should be kept, false otherwise
    """
    chromosome_regex = re.compile(r"^>(\S*)(\s?)(.*)")
    keep_chromosome = False
    for line in input_file:
        match = chromosome_regex.match(line)
        if match:
            chromosome = match.group(1)
            keep_chromosome = filter_function(chromosome)
            if keep_chromosome:
                output_file.write(line)
        elif keep_chromosome:
            output_file.write(line)


def filter_chromosomes_gff(input_file: TextIO, output_file: TextIO, filter_function: Callable[[str], bool]):
    """
    Converts chromosomes in input GFF/GTF file.

    :param input_file: GFF file with chromosomes to convert
    :param output_file: output GFF file with chromosomes replaced
    :param filter_function: function that should return true if chromosome should be kept, false otherwise
    """
    for line in input_file:
        if line.startswith("#"):
            output_file.write(line)
            continue
        columns = line.rstrip("\r\n").split("\t")
        chromosome = columns[0]
        keep_chromosome = filter_function(chromosome)
        if keep_chromosome:
            output_file.write(line)


def parse_chromosome_list(list_file: TextIO) -> set[str]:
    """
    Parses a list of chromosome names.

    :param list_file: list containing chromosome names
    :return: list containing chromosome names
    """
    chromosomes = set()
    for line in list_file:
        if line.startswith("#"):
            continue
        chromosomes.add(line.rstrip("\r\n"))
    return chromosomes


if __name__ == '__main__':
    main()
