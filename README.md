# biocloud docker library

Central location for docker images used by RTI's cloud-based bioinformatics toolkit.

## Layout

Dockerfiles are in the structure `<tool-name>/<tool-version>/Dockerfile`.

## Committing to repo

Only include changes to 1 Dockerfile or Dockerfile's related files per commit. i.e. Don't commit to 2 different directories in the same commit.

### New Dockerfiles

The GitHub action will build and push the Docker Image to Docker Hub. If a repo does not exist, the push command will create it.

## Docker Hub Repo

All Docker Images are pushed to Docker Hub here: https://hub.docker.com/u/rtibiocloud

The repository is the tool name. Images are tagged in the format `<tool-version>_<first-6-git-sha>`.
