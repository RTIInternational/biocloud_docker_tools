# Description

This Docker image contains an in-house script written to create an Excel workbook of a file and folder manifest of a Seven Bridges project.  Its purpose is to get a sense of how folders are structured, how much space is used, and how many files exits.  The Input to this should be a Seven Bridges developer's token and a string indicating which project to get a manifest of, and the output is an Excel file with a manifest of files and folders of the specified Seven Bridges project.  The following information is provided about the project and its files and folders:

Summary metrics:
- Report Date - date manifest was generated
- Project ID - supplied project ID in format "\<username\>/\<project-name\>"
- Project URL - Seven Bridges platform URL in format "https://platform.sb.bioodatacatalyst.nhlbi.nih.gov/u/\<username\>/\<project-name\>"
- Total number of files uploaded
- Total size of uploaded files
- Most recent upload - date and time of most recently uploaded file

Folders:
- Hierarchy of folders in project
- Number of files in each folder

Files:
- File name
- File Size
- Upload Date
- Path - path to folder where file is located
- SB URI - URI of file in Seven Bridges in format "https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2/files/\<file-id\>"

## Sample usage

Build
```
docker build -t generate_manifest_sevenbridges:v1 .
```

Run
```
docker run -it -v $PWD:/data generate_manifest_sevenbridges:v1 Rscript generate_manifest_sevenbridges.R
```

Usage info:
```
Usage: convert_ab1_to_fasta.r [OPTIONS]
             -- Required Parameters --
              [-t | --token         ]    <Seven Bridges Developer token> (REQUIRED)
              [-p | --project_id    ]    <Project ID, e.g. "username/test-project"> (REQUIRED)
             -- Optional Parameters -- 
              [-v | --verbose       ]    <Activates verbose mode>
             -- Help Flag --  
              [-h | --help          ]    <Displays this help message>
             Example:
             convert_ab1_to_fasta.r -v -t <token-here> -p <project_id-here>
```

## Files included

- `Dockerfile`: the Docker file used to build this image
- `generate_manifest_sevenbridges.R`: R script that serves as the main executable when the Docker container is run.  Expected behavior is to call the Seven Bridges API recursively on a project and generate an Excel report containing the project's summary metrics, a directory manifest, and a file manifest.  In the end, this writes the extracted results to an output Excel sheet (.xlsx) named after the project's name.

## Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- David Williams, email: dnwilliams@rti.org
