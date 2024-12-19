# Description

This Docker image contains a script to tag files within a project with the RMIP file formatting.

### Inputs
- Seven Bridges Developer token (Required)
- Seven Bridges api endpoint (default = "https://api.sb.biodatacatalyst.nhlbi.nih.gov/v2")
- project ID e.g. "username/test-project" (Required)
- folder (optional, use if wanting to tag a specific folder within a project)

### Run
```
docker run -it -v $PWD:/scratch file_tag_sevenbridges:v1.0 Rscript file_tagging.R \
  -t <token_here> \
  -a <api_endpoint_here> \
  -p <project_id_here> \
  -f <folder_name_here>
```

### Files included

- `Dockerfile`: the Docker file used to build this image
- `file_tagging.R`: R script that serves as the main executable when the Docker container is run.  Expected behavior is to call the Seven Bridges API recursively on a project to collect the file ids within a project or folder and tag the files with the RMIP file tagging format. If any file does not match the RMIP file formatting, it is documented in the log file.

File tagging documentation: https://bdcatalyst.freshdesk.com/support/discussions/topics/60000407796

### Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- Caryn Willis, email: cdwillis@rti.org
