# Use an official Python runtime as the base image
FROM python:3.12.6-slim

# Add Container Labels
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"
LABEL description="Tools for launching WGS QC workflow"

# Install System Dependencies
RUN apt-get update && apt-get install -y \
    less \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /opt/

# Install the required dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Add scripts
ADD entrypoint.sh /opt/
ADD create_step_2_config.py /opt/
ADD start_run.py /opt/

# Set permissions
RUN chmod 755 /opt/entrypoint.sh
RUN chmod 755 /opt/create_step_2_config.py
RUN chmod 755 /opt/start_run.py

# Set the entry point command
ENTRYPOINT [ "/opt/entrypoint.sh" ]
