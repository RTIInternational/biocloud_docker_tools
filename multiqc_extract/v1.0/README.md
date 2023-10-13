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

Build
```
docker build -t multiqc_extract:v1 .
```

Run
```
docker run -it -v $PWD:/data multiqc_extract:v1 Rscript unzip_extract_stats.R
```

## Files included

- `Dockerfile`: the Docker file used to build this image
- `unzip_extract_stat.R`: R script that serves as the main executable when the Docker container is run.  Expected behavior is to take all input ZIP files from FastQC in the current working directory, unzip it, and parse data from the JSON files and various text files returned.  In the end, this writes the extracted results to an output CSV file called `output.csv`.

## Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- David Williams, email: dnwilliams@rti.org
