# Imputation Server 2 v2.0.7

## Copy Dockerfile from imputationserver2 repo

``` bash
cd /shared/ngaddis/git
git clone git@github.com:genepi/imputationserver2.git
cd imputationserver2
git checkout v2.0.7
cp /shared/ngaddis/git/imputationserver2/Dockerfile /shared/ngaddis/git/biocloud_docker_tools/imputationserver2/v2.0.7/
cp /shared/ngaddis/git/imputationserver2/environment.yml /shared/ngaddis/git/biocloud_docker_tools/imputationserver2/v2.0.7/
mkdir -p /shared/ngaddis/git/biocloud_docker_tools/imputationserver2/v2.0.7/files/bin
cp /shared/ngaddis/git/imputationserver2/files/bin/* /shared/ngaddis/git/biocloud_docker_tools/imputationserver2/v2.0.7/files/bin/
```
