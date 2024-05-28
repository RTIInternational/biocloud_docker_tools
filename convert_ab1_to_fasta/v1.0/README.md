# Description

This Docker image contains an in-house script written to convert AB1 files into FASTA files.  Its purpose is to fit into the traditional Sanger sequencing workflow to process outputs into a machine readable format.  The input to this should be a directory containing AB1 file(s), and the output is a FASTA file renamed with a prepended linker string.

Given the example linker `RMIP_001_002_A_003_B`, this can be separated into different components, delimited by `_`.  Details on the linker and its format are below.

| Name | Component | Description |
| -- | -- | -- |
|  RMIP identifier | `RMIP` | Goes at the beginning of each linker |
|  Project Identifier | `001` | Numeric only |
|  Participant ID | `002` | Numeric only |
|  Discriminator | `A` | Alphabetic only - combination with "Identifier" uniquely identifies every collection event |
|  Identifier | `003` | Numeric only - combination with "Discriminator" uniquely identifies every collection event |
|  Vial identifier (alphabetic) | `B` | Alphabetic only - identifies specific collection aliquot - optional if only one vial |

## Sample usage

This script is used to convert .ab1 files into .fa files.

Build
```
docker build -t convert_ab1_to_fasta:v1 .
```

Run
```
docker run -it -v $PWD:/data convert_ab1_to_fasta:v1 Rscript convert_ab1_to_fasta.r -i <path-to-input-ab1> -l <input-linker-string>
docker run -it -v $PWD:/data convert_ab1_to_fasta:v1 Rscript convert_ab1_to_fasta.r -v -i ./my_data/006C003_matK-GATC-M13-RPells-1289382.ab1 -l RMIP_001_001_A_001_A -o "Homo Sapiens" -m "RNA" -g "SOX2" -d "Here is a test description"
```

Usage info:
```
Usage: convert_ab1_to_fasta.r [OPTIONS]
             -- Required Parameters --
              [-i | --input_filename]    <Path to input ab1 file> (REQUIRED)
              [-l | --linker        ]    <String identifier for sample> (REQUIRED, e.g. "RMIP_001_001_A_001_A")
             -- Optional Parameters -- 
              [-v | --verbose       ]    <Activates verbose mode>
              [-o | --organism      ]    <String for organism sample came from, e.g. "Homo Sapiens">
              [-m | --molecule_type ]    <String for molecule type, e.g. "DNA" or "RNA">
              [-g | --target_gene   ]    <String telling target gene, e.g. "SOX2">
              [-d | --description   ]    <String with description of sequence, e.g. "Homo Sapiens SRY-Box Transcription Factor 2 (SOX2) mRNA, exon 1">
              [-r | --read_mode_in  ]    <Single character identifier telling whether to do Forward or Reverse read, i.e. F or R>
             -- Help Flag --  
              [-h | --help   ]           <Displays this help message>
             Example:
             convert_ab1_to_fasta.r -v -i ./my_data/006C003_matK-GATC-M13-RPells-1289382.ab1 -l RMIP_001_001_A_001_A -o "Homo Sapiens" -m "RNA" -g "SOX2" -d "Here is a test description"
```

## Files included

- `Dockerfile`: the Docker file used to build this image
- `convert_ab1_to_fasta.r`: R script that serves as the main executable when the Docker container is run.  Expected behavior is to take a specified .ab1 file, copy that to a temporary directory, and rename it to include a prefix signifying a sample name.  This renamed file is written to the current working directory.

## Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- David Williams, email: dnwilliams@rti.org
