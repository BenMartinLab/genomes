#!/usr/bin/env python3

import argparse
import os
import re
import sys
from typing import TextIO


def file_path(string):
    if os.path.isfile(string):
        return string
    else:
        raise FileNotFoundError(string)


def main(argv: list[str] = None):
    parser = argparse.ArgumentParser(description="Converts chromosomes in input file.")
    parser.add_argument('input', nargs='?', type=argparse.FileType('r'), default=sys.stdin,
                        help="Input file with chromosomes to convert")
    parser.add_argument('output', nargs='?', type=argparse.FileType('w'), default=sys.stdout,
                        help="Output file with chromosomes replaced")
    parser.add_argument('-f', '--format', choices = ['fasta', 'gff'], default=None,
                        help="Input file format  (default: type is guessed using filename extension)")
    parser.add_argument('-d', '--delete', action="store_true", default=False,
                        help="Remove entries associated to a chromosomes without replacement  (default: %(default)s)")
    parser.add_argument('-m', '--mapping', type=argparse.FileType('r'), default="chromAlias.txt",
                        help="Tab delimited text file containing source chromosomes and converted chromosomes  "
                             "(default: %(default)s)")
    parser.add_argument('-s', '--source_column', type=int, default='1',
                        help="Column index of source chromosomes in mapping file - 1 means first column of file" +
                             "   (default: %(default)s)")
    parser.add_argument('-c', '--converted_column', type=int, default='2',
                        help="Column index of converted chromosomes in mapping file - 1 means first column of file" +
                             "   (default: %(default)s)")

    args = parser.parse_args(argv)
    convert_chromosome(input_file=args.input, output_file=args.output, mapping_file=args.mapping,
                       input_format=args.format, delete=args.delete,
                       mapping_source_column=args.source_column - 1,
                       mapping_converted_column=args.converted_column - 1)


def convert_chromosome(input_file: TextIO, output_file: TextIO, mapping_file: TextIO, input_format: str = None,
                       delete: bool = False,
                       mapping_source_column: int = 0, mapping_converted_column: int = 1):
    """
    Converts chromosomes in input file.

    :param input_file: input file with chromosomes to convert
    :param output_file: output file with chromosomes replaced
    :param input_format: input file format  (default: type is guessed using filename extension)
    :param delete: remove entries associated to a chromosomes without replacement
    :param mapping_file: tab delimited text file containing source chromosomes and converted chromosomes
    :param mapping_source_column: column index of source chromosomes in mapping file
    :param mapping_converted_column: column index of converted chromosomes in mapping file
    """
    mappings = parse_mapping(mapping_file=mapping_file, source_column=mapping_source_column,
                             converted_column=mapping_converted_column)

    if not input_format:
        try:
            filename = input_file.name.lower()
            if filename.endswith(".fasta") or filename.endswith(".fa") or filename.endswith(".fna"):
                input_format = "fasta"
            elif filename.endswith(".gff") or filename.endswith(".gtf"):
                input_format = "gff"
        except AttributeError:
            print(f"Input is not a file and no format parameter was given", file=sys.stderr)

    if input_format == "fasta":
        convert_chromosomes_fasta(input_file=input_file, output_file=output_file, mappings=mappings, delete=delete)
    elif input_format == "gff":
        convert_chromosomes_gff(input_file=input_file, output_file=output_file, mappings=mappings, delete=delete)
    else:
        print(f"File format {input_format} not implemented yet.", file=sys.stderr)


def convert_chromosomes_fasta(input_file: TextIO, output_file: TextIO, mappings: dict[str, str], delete: bool = False):
    """
    Converts chromosomes in input FASTA file.

    :param input_file: FASTA file with chromosomes to convert
    :param output_file: output FASTA file with chromosomes replaced
    :param mappings: dictionary of input chromosomes to output chromosomes
    :param delete: remove entries associated to a chromosomes without replacement
    """
    missing_chromosomes = set()
    chromosome_regex = re.compile(r"^>(\S*)(\s?)(.*)")
    delete_sequence = False
    for line in input_file:
        match = chromosome_regex.match(line)
        if match:
            chromosome = match.group(1)
            if chromosome in mappings:
                delete_sequence = False
                output_file.write(f">{mappings[chromosome]}{match.group(2)}{match.group(3)}\n")
            else:
                delete_sequence = delete
                if chromosome not in missing_chromosomes:
                    missing_chromosomes.add(chromosome)
                    print(f"Chromosome {chromosome} not found in mapping file", file=sys.stderr)
                if not delete:
                    output_file.write(line)
        elif not delete_sequence:
            output_file.write(line)


def convert_chromosomes_gff(input_file: TextIO, output_file: TextIO, mappings: dict[str, str], delete: bool = False):
    """
    Converts chromosomes in input GFF/GTF file.

    :param input_file: GFF file with chromosomes to convert
    :param output_file: output GFF file with chromosomes replaced
    :param mappings: dictionary of input chromosomes to output chromosomes
    :param delete: remove entries associated to a chromosomes without replacement
    """
    missing_chromosomes = set()
    for line in input_file:
        if line.startswith("#"):
            output_file.write(line)
            continue
        columns = line.rstrip("\r\n").split("\t")
        chromosome = columns[0]
        if chromosome in mappings:
            other_columns = "\t".join(columns[1::])
            output_file.write(f"{mappings[chromosome]}\t{other_columns}\n")
        else:
            if chromosome not in missing_chromosomes:
                missing_chromosomes.add(chromosome)
                print(f"Chromosome {chromosome} not found in mapping file", file=sys.stderr)
            if not delete:
                output_file.write(line)


def parse_mapping(mapping_file: TextIO, source_column: int = 0, converted_column: int = 1) \
        -> dict[str, str]:
    """
    Parse mapping file.

    :param mapping_file: tab delimited dile
    :param source_column: index of source id columns
    :param converted_column: index of converted id columns
    :return: dictionary of source id to converted id
    """
    mappings = {}
    for line in mapping_file:
        if line.startswith("#"):
            continue
        columns = line.rstrip('\r\n').split('\t')
        source = columns[source_column]
        converted = columns[converted_column]
        mappings[source] = converted
    return mappings


if __name__ == '__main__':
    main()
