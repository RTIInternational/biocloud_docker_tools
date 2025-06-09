# plink2 Docker Image

This Docker image contains the `plink2` binary (version 2.0.0-a.6.15, 2025-06-04, AVX2 build), downloaded from:<br>
🔗 https://s3.amazonaws.com/plink2-assets/alpha6/plink2_linux_amd_avx2_20250604.zip

## Usage

Run `plink2` using Docker:

```bash
docker run --rm -v $(pwd):/data rtibiocloud/plink:v2.0.0-a.6.15_<latest-commit> plink2 --help
```

## Contact
For help contact Jesse Marks (jmarks@rti.org).
