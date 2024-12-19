# Description

This Docker image contains the 7z tool for compressing and uncompressing files.  The intended use for this image is to decompress files in Seven Bridges.  Confirmed supported files to decompress include:

- 7z
- bz
- bz2
- gz
- rar
- tar
- tbz
- tb2
- zip

## Sample usage

This script is used to extract files from a given compressed file.

Build
```
docker build -t unzip_sevenbridges:v1 .
```

Run
```
docker run -it -v $PWD:/data unzip_sevenbridges:v1 7z e <file> -o<output_directory>
```

## Files included

- `Dockerfile`: the Docker file used to build this image

## Contact

If you have any questions or feedback, please feel free to contact the maintainers of this project:

- David Williams, email: dnwilliams@rti.org
