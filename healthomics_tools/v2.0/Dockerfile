# Use an official Python runtime as the base image
FROM python:3.12-slim 

# Add Container Labels
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"
LABEL description="Tools for interacting with AWS HealthOmics"

# Install System Dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    less \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /opt/

# Install the required dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Add scripts
ADD cancel_runs.py /opt/
ADD create_wf.py /opt/
ADD create_wf_version.py /opt/
ADD delete_runs.py /opt/
ADD entrypoint.sh /opt/
ADD healthomics_utils.py /opt/
ADD retrieve_run_results.py /opt/
ADD start_run.py /opt/

# Set permissions
RUN chmod -R 755 /opt

# Set the entry point command
ENTRYPOINT [ "/opt/entrypoint.sh" ]
