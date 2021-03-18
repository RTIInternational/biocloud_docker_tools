FROM ubuntu:18.04

# Add scripts to make it run
ADD extract_by_id.pl /
ADD run.sh /

# Add to /opt folder
RUN mkdir /opt/code_docker_lib
RUN mv extract_by_id.pl /opt/code_docker_lib
RUN mv run.sh /opt/code_docker_lib

# Change permissions to make things exectuable
RUN chmod u+x /opt/code_docker_lib/run.sh
RUN chmod u+x /opt/code_docker_lib/extract_by_id.pl

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Create entrypoint that runs the run.sh wrapper script
ENTRYPOINT ["/bin/bash", "/opt/code_docker_lib/run.sh"]