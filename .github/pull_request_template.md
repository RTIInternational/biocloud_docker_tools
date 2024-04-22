# Description
_Provide an overview..._

<br>


### Dockerfile Structure and Organization:
- [ ] Does the Dockerfile build?
- [ ] Is tool organized according to [Repository Structure](https://github.com/RTIInternational/biocloud_docker_tools/blob/master/README.md#repository-structure)? 
- [ ] Specific base image with a version tag, e.g., `FROM ubuntu:20.04` instead of `FROM ubuntu`.
- [ ] Add comments to describe each Dockerfile step.

<br>

### Metadata
Include the following LABELs:
- [ ] `LABEL maintainer="Your Name <your.email@rti.org>"`
- [ ] `LABEL base-image="ubuntu:22.04"`
- [ ] `LABEL description="Short description of the purpose of this image"`
- [ ] `LABEL software-website="https://example.com"`
- [ ] `LABEL software-version="1.0.0"`
- [ ] `LABEL license="https://www.example.com/legal/end-user-software-license-agreement"`

<br>

### File and Resource Management:
- [ ] Store scripts, files, and software tools ONLY in `/opt`. 
- [ ] Removing tar files after extraction and delete temporary files and caches generated during the build process.
- [ ] Ensure sensitive data (e.g., API keys, passwords) is not hardcoded in the Dockerfile.

<br>

### Container Behavior 
- [ ] Specify a meaningful `CMD` to define how the container should run by default (help message is a good default).

<br>

### Assign reviewer
- [ ] Request review (default: @jaamarks)
