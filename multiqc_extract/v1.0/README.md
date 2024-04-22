# Description

This Docker image contains an in-house script written to extract several key stats of interest from a MultiQC run coming off of a FastQC analysis.  Its purpose is to fit in the Whole Genome Sequencing workflow in the RMIP project.  The Input to this should be ZIP file(s) coming from a FastQC run, and the output is a CSV file with rows containing extracted information for each input file.  Results parsed from the MultiQC run are as follows:

- Sample name
- Total number of sequences
- Read length
- Highest per sequence quality score
- Average and Standard Deviation per base sequence content (taken after 30 cycles)
- Average and Standard Deviation sequence duplication level as percentage of duplicates
- Average and Standard Deviation per base % N content

## Sample usage

This script is intended to be run after all FASTQ files have gone through MultiQC analysis.  A quality check was implemented to see if all FASTQ files have been processed or not.

Build
```
docker build -t multiqc_extract:v1 .
```

Run
```
docker run -it -v $PWD:/data multiqc_extract:v1 Rscript unzip_extract_stats.R
```

Usage info:
```
Usage: unzip_extract_stats.R
             -- Required Parameters --
              NONE
             -- Optional Parameters -- 
              [-i | --inputpath]    <Name of input working directory> (default = .)
              [-o | --outfile  ]    <The output file name> (default = output.csv)
              [-p | --outpath  ]    <Path to the directory to save the outputs> (default = input path)
             -- Help Flag --  
              [-h | --help     ]    <Displays this help message>
             Example:
             unzip_extract_stats.R -i results_2023_01_01 -o my_test_results.csv -p my_test_run
```

## Files included

- `Dockerfile`: the Docker file used to build this image
- `unzip_extract_stat.R`: R script that serves as the main executable when the Docker container is run.  Expected behavior is to take all input ZIP files from FastQC in the current working directory, unzip it, and parse data from the JSON files and various text files returned.  In the end, this writes the extracted results to an output CSV file called `output.csv`.

## Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- David Williams, email: dnwilliams@rti.org
