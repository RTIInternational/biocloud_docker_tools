# Description

This Docker image contains miRDeep2 for discovering active known or novel miRNAs from sequencing data.

### Inputs
- fasta file of trimmed miRNAseq data
- miRBase miRNA reference file
- genome reference files

### Run
```
docker run -it -v $PWD:/scratch mirdeep2:`version` <miRDeep2 options here>
```
miRDeep2 options and examples can be found [here](https://www.mdc-berlin.de/content/mirdeep2-documentation?mdcbl%5B0%5D=/n-rajewsky%23t-data%2Csoftware%26resources&mdctl=0&mdcou=20738&mdcot=6&mdcbv=crsjgo3KpH2eVDwEmJ_-5lh5FYkn8dZh4PNU6NsBrTE).
### Files included

- `Dockerfile`: the Docker file used to build this image

### Output
- A spreadsheet and a html file with an overview of all detected miRNAs in the deep sequencing input data.

### Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- Caryn Willis, email: cdwillis@rti.org
