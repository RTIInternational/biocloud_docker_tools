# Description

This Docker image contains an in-house script written to extract several key stats of interest from a MultiQC run coming off of a FastQC analysis.  Its purpose is to fit in the Whole Genome Sequencing workflow in the RMIP project.  The Input to this should be a ZIP file coming from a FastQC run, and the output is a CSV file with a row containing extracted information.  Results parsed from the MultiQC run are as follows:

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
docker run -it -v $PWD:/usr/local/src/myscripts multiqc_extract:v1 bash
```

## Files included

- `Dockerfile`: the Docker file used to build this image
- `unzip_extract_stat.sh`: Bash shell script that serves as the main executable when the Docker container is run.  Expected behavior is to take an input ZIP file from FastQC, unzip it, and parse data from the JSON file and various text files returned.  In the end, this writes the extracted results to an output CSV file called `output.csv`.
- `extract_max_per_seq_quality_score.r`: R script to extract the max per sequence quality score
- `extract_per_base_n_content.r`: R script to extract the average and sd sequence duplication level
- `extract_per_base_seq_quality.r`: R script to extract the average and sd per base sequence content
- `extract_seq_duplication_level.r`: R script to extract the average and sd sequence duplication level

## Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- David Williams, email: dnwilliams@rti.org
