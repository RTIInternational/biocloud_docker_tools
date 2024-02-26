# Use an official Python runtime as the base image
FROM python:3.12-slim

# Add Container Labels
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL description="A script to generate presigned URLs to upload to S3."

# Install System Dependencies
RUN apt-get update && apt-get install -y \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /opt/

# Copy the script and requirements file to the container
COPY s3_presigned_upload.py requirements.txt ./

# Install the required dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set the entry point command
ENTRYPOINT ["python", "s3_presigned_upload.py"]

# Set the default command arguments
CMD ["--help"]
