# Eigensoft
The wrapper script smartpca.perl calls smartpca to calculate eigen-vectors and eigen-values.

## example code

```shell
   docker run -i -v $procD:/data/ \
   rtibiocloud/eigensoft:v6.1.4_e0eb071 \
    /opt/EIG-6.1.4/bin/smartpca.perl \
        -i $bedfile \
        -a $bimfile \
        -b $famfile \
        -o /data/$an/eig/results/${an}_ld_pruned.pca \
        -p /data/$an/eig/results/${an}_ld_pruned.plot \
        -e /data/$an/eig/results/${an}_ld_pruned.eval \
        -l /data/$an/eig/results/${an}_ld_pruned.pca.log \
        -m 0
```
