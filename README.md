# RTI BioCloud Docker Library

Welcome to the RTI BioCloud Docker Library! This repository serves as a central location for building and cataloging the Docker images used by RTI's cloud-based bioinformatics toolkit.

## Repository Structure

The Dockerfiles are organized in the following structure: `<tool_name>/<tool_version>/Dockerfile`. Each tool has its own directory containing the Dockerfile and related files.
If a software tool does not have a version (e.g., a custom script), use `v1` for the tool-version folder (e.g., rti_tool/v1/Dockerfile). Tool names should contain only lowercase characters and underscores (not hyphens) should be used to separate words. 

<br><br>

# Developers
Commiting a Dockerfile to this repository will automatically result in the building of a new docker image that is uploaded to Docker Hub. To submit a commit developers should complete the following steps: 
1. Fork this repository to their account (if not previously done).
2. Create a branch for the specific docker you working on.
* Create the necessary directory structure when applicable as described above. **Not sure how to make this just an indented bullet**
4. Create the Dockerfile and appropriate documentation and commit to the branch you created in step 2.
5. Create a pull request to merge this with this repository
6. Address any comments that come up during the review.

## Dockerfile Best Practices Checklist
Once a pull request has been received, the repository administrators will review the commit and check for the following items:
<br><br>
**Basic Information**
- [ ] Test the Dockerfile locally by building an image, running a container, and confirming it works as expected while remaining clean and functional.
- [ ] Choose a specific base image with a version tag, e.g., `FROM ubuntu:20.04` instead of `FROM ubuntu`.
- [ ] Add comments to describe each Dockerfile step, including complex or non-standard configurations.
- [ ] Store scripts, files, and software tools in the `/opt` directory to prevent cluttering the root directory.
- [ ] Reduce image size by removing tar files after extraction and delete temporary files and caches generated during the build process.
- [ ] Ensure sensitive data (e.g., API keys, passwords) is not hardcoded in the Dockerfile.
- [ ] Specify a meaningful `ENTRYPOINT` or `CMD` to define how the container should run.
- [ ] Include minimum LABELs:
  - [ ] `LABEL maintainer="Your Name <your.email@example.com>"`
  - [ ] `LABEL description="Short description of the purpose of this image"`
  - [ ] `LABEL software-website="https://example.com"`

**Committing**
- [ ] Organize each tool based off of the guide above in the [Respository Structure](#repository-structure) section above.
- [ ] Commit changes to a single Dockerfile and its associated files at a time. No multi-directory commits.
- [ ] Verify build was successful and that the tool is available on Docker Hub (see the [Docker Hub](#docker-hub) section below). 
- [ ] Maintain documentation alongside the Dockerfile, describing how to build, run, and use the image.

<br><br>

## Review Process
Each pull request received will be subject to a review process that will confirm that checklist items are addressed. The review process will consist of 
1. **Review Code:** Check for syntax errors, coding standards, and best practices.
2. **Review Documentation:** Ensure that comments and READMEs are clear and informative.
3. **Review Execution:** Verify that the Dockerfile builds locally.

If all three of these review stages are satisfactory then the approval will be given to merge the pull request and initiate the build of the docker image. 

# Docker Hub

All Docker images are published on Docker Hub under the RTI BioCloud organization. You can find the repository at https://hub.docker.com/u/rtibiocloud. Each image is tagged using the following format: `<tool-version>_<first-6-characters-of-git-hash>`.

When adding new Dockerfiles, the GitHub action will automatically build and push the Docker images to Docker Hub. If the corresponding repository does not exist, the push command will create it.

<br><br>

# Contact Us

If you have any questions, suggestions, or need assistance, please feel free to reach out to our team:

- Nathan Gaddis (ngaddis@rti.org)
- Jesse Marks (jmarks@rti.org)
- Bryan Quach (bquach@rti.org)
