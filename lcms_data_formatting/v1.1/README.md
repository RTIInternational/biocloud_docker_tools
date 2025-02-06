# Description

This Docker image contains a script to format LCMS xlsx files.

### Inputs
- LCMS xlsx file
- Column name converter file (.csv) with current column names in the 1st column, new column names in the second column, no header
- columns to drop file (.csv, optional) with list of column names to drop if different from the default: "# Usable QC","RSD QC Areas [%]","RT [min]", "Name"

### Run
```
docker run -it -v $PWD:/scratch lcms_data_formatting:v1.0 Rscript LCMS_file_formatter.R \
  -f <lcms_file_here> \
  -c <column_converter_here> \
  -d <columns_to_drop_here>
```

### Files included

- `Dockerfile`: the Docker file used to build this image
- `LCMS_file_formatter.R`: R script that serves as the main executable when the Docker container is run.  Expected behavior is to format the LCMS file by removing unnecessary rows and columns and rename column names to match correct sample prefix.

### Output
- This script will output a .xlsx and .csv set of files of the formatted LCMS data. It will be in the format of *lcms_file_name*_formatted.xlsx.

### Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- Caryn Willis, email: cdwillis@rti.org
