FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gzip \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    pandas>=1.3.0 \
    numpy>=1.20.0

# Copy the preprocessing script
COPY genomic_sem_preprocessing.py /app/

# Make script executable
RUN chmod +x /app/genomic_sem_preprocessing.py

# Set the default entrypoint
ENTRYPOINT ["python3", "/app/genomic_sem_preprocessing.py"]
CMD ["--help"]
