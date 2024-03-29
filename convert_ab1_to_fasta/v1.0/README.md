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
```

Usage info:
```
Usage: convert_ab1_to_fasta.r [OPTIONS]
             -- Required Parameters --
              [-i | --input_dir]    <Path to input ab1 file(s)> (REQUIRED)
              [-l | --linker   ]    <String identifier for sample> (REQUIRED, e.g. RMIP_001_001_A_001_A)
             -- Optional Parameters -- 
              [-v | --verbose  ]    <Activates verbose mode>
             -- Help Flag --  
              [-h | --help     ]    <Displays this help message>
             Example:
             convert_ab1_to_fasta.r -v -i ./my_data -l RMIP_001_001_A_001_A
```

## Files included

- `Dockerfile`: the Docker file used to build this image
- `convert_ab1_to_fasta.r`: R script that serves as the main executable when the Docker container is run.  Expected behavior is to take all input AB1 files from the specified directory, copy those to a temporary directory, and rename those files to include a prefix signifying a sample name.  This writes those specific files to the current working directory.

## Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- David Williams, email: dnwilliams@rti.org
