# RTI BioCloud Docker Library

Welcome to the RTI BioCloud Docker Library! This repository serves as a central location for Docker images used by RTI's cloud-based bioinformatics toolkit.

## Repository Structure

The Dockerfiles are organized in the following structure: `<tool-name>/<tool-version>/Dockerfile`. Each tool has its own directory containing the Dockerfile and related files.

## Documentation for New Tools

When adding a new tool to the library, it is essential to provide clear and comprehensive documentation. We recommend creating a `README.md` file within the tool's directory. The README should include descriptions, usage instructions, and examples of how to use the tool with the provided Docker image. This will help analysts understand the purpose and functionality of the tool, enabling them to utilize it effectively.

## Docker Hub Repository

All Docker images are published on Docker Hub under the RTI BioCloud organization. You can find the repository at [https://hub.docker.com/u/rtibiocloud](https://hub.docker.com/u/rtibiocloud). Each image is tagged using the following format: `<tool-version>_<first-6-characters-of-git-sha>`.
<br><br>



## Commit Guidelines

To maintain a clean and organized repository, please follow these guidelines when committing changes:

- Each commit should include changes related to only one Dockerfile or its associated files.
- Avoid committing changes to multiple directories in the same commit.

### Adding New Dockerfiles

When adding new Dockerfiles, the GitHub action will automatically build and push the Docker images to Docker Hub. If the corresponding repository does not exist, the push command will create it.
<br><br>



## GitHub Action Details

The GitHub action used in this repository is based on the code from [Publish-Docker-Github-Action](https://github.com/elgohr/Publish-Docker-Github-Action). It provides automated building and publishing of Docker images when changes are pushed to the repository.
<br><br>



## Contact Us

If you have any questions, suggestions, or need assistance, please feel free to reach out to our team:

- Nathan Gaddis (ngaddis@rti.org)
- Jesse Marks (jmarks@rti.org)
- Bryan Quach (bquach@rti.org)

We are here to help and support you in any way we can.
