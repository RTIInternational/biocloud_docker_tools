# RTI BioCloud Docker Library

Welcome to the RTI BioCloud Docker Library! This repository serves as a central location for Docker images used by RTI's cloud-based bioinformatics toolkit.

## Repository Structure

The Dockerfiles are organized in the following structure: `<tool-name>/<tool-version>/Dockerfile`. Each tool has its own directory containing the Dockerfile and related files.
If a software tool does not have a version, with a custom script for example, use `v1` for the tool-version folder.


<br><br>

# Developers
## Dockerfile Best Practices Checklist

**Basic Information**
- [ ] Test the Dockerfile locally by building an image, running a container, and confirming it works as expected while remaining clean and functional.
- [ ] Choose a specific base image with a version tag, e.g., `FROM ubuntu:20.04` instead of `FROM ubuntu`.
- [ ] Add comments to describe each Dockerfile step, including complex or non-standard configurations.
- [ ] Store scripts, files, and software tools in the `/opt` directory to prevent cluttering the root directory.
- [ ] Reduce image size by removing tar files after extraction and delete temporary files and caches generated during the build process.
- [ ] Ensure sensitive data (e.g., API keys, passwords) is not hardcoded in the Dockerfile.
- [ ] Specify a meaningful `ENTRYPOINT` or `CMD` to define how the container should run.
- [ ] Maintain documentation alongside the Dockerfile, describing how to build, run, and use the image.
- [ ] Include minimum LABELs:
  - [ ] `LABEL maintainer="Your Name <your.email@example.com>"`
  - [ ] `LABEL description="Short description of the purpose of this image"`
  - [ ] `LABEL software-website="https://example.com"`

**Committing**

- [ ] Organize each tool based off of the guide above in the [Respository Structure](respository-structure) section above.
- [ ] Commit changes to a single Dockerfile and its associated files at a time. No multi-directory commits.
- [ ] Verify build was successful and that the tool is available on Docker Hub (see the [Docker Hub](docker-hub) section below). 


<br><br>

# Docker Hub

All Docker images are published on Docker Hub under the RTI BioCloud organization. You can find the repository at https://hub.docker.com/u/rtibiocloud. Each image is tagged using the following format: `<tool-version>_<first-6-characters-of-git-hash>`.

When adding new Dockerfiles, the GitHub action will automatically build and push the Docker images to Docker Hub. If the corresponding repository does not exist, the push command will create it.


<br><br>

# Contact Us

If you have any questions, suggestions, or need assistance, please feel free to reach out to our team:

- Nathan Gaddis (ngaddis@rti.org)
- Jesse Marks (jmarks@rti.org)
- Bryan Quach (bquach@rti.org)
