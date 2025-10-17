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
ADD delete_runs.py /opt/
ADD entrypoint.sh /opt/
ADD healthomics_utils.py /opt/
ADD retrieve_run_results.py /opt/
ADD start_run.py /opt/

# Set permissions
RUN chmod 755 /opt/cancel_runs.py
RUN chmod 755 /opt/create_wf.py
RUN chmod 755 /opt/delete_runs.py
RUN chmod 755 /opt/entrypoint.sh
RUN chmod 755 /opt/healthomics_utils.py
RUN chmod 755 /opt/retrieve_run_results.py
RUN chmod 755 /opt/start_run.py

# Set the entry point command
ENTRYPOINT [ "/opt/entrypoint.sh" ]
