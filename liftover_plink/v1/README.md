# Liftover on Plink files
Genotypes are often in the Plink [bed/bim/fam](https://www.cog-genomics.org/plink/1.9/formats#bed) format. When we need to perform a liftover to a different genome build (e.g., hg18 -> hg19) we can use this Python wrapper. 

liftOverPlink adopted from a script on GitHub [here](https://github.com/sritchie73/liftOverPlink), which was a modification from the [liftMap.py](http://genome.sph.umich.edu/wiki/LiftMap.py) script provided by the [Abecasis Lab](http://genome.sph.umich.edu/wiki/Abecasis_Lab). We updated liftOverPlink from Python2 to Python3.


## Example code

```bash
cd /home/ec2-user/rti-shared/shared_data/pre_qc/whi_garnet/genotype/array/observed/0001/c1/phg000139.v1.GARNET_WHI.genotype-calls-matrixfmt.c1/sample_level_unfiltered_PLINK_set/

# convert to PED/MAP format
mkdir liftover/
docker run -v $PWD:/data/ -it rtibiocloud/plink:v1.9_178bb91 plink \
    --bfile /data/GARNET_WHI_TOP_sample_level_c1 \
    --recode \
    --out /data/liftover/garnet_whi_c1

# apply liftOverPlink.py to update hg18 to hg19 or hg38
docker run -v $PWD:/data/ rtibiocloud/liftover_plink:v1_93cbe47 python3 /opt/liftOverPlink.py \
    -m /data/garnet_whi_c1.map \
    -p /data/garnet_whi_c1.ped \
    -o /data/garnet_whi_c1_hg19 \
    -c /opt/hg18ToHg19.over.chain.gz \ # note to change this based on the liftover you are performing.
    -e /opt/liftOver

#Converting MAP file to UCSC BED file...
#SUCC:  map->bed succ
#Lifting BED file...
#Reading liftover chains
#Mapping coordinates
#SUCC:  liftBed succ
#Converting lifted BED file back to MAP...
#SUCC:  bed->map succ
#Updating PED file...
#SUCC:  liftPed succ
#cleaning up BED files...

# convert back to bed/bim/fam
docker run -v $PWD:/data/ -it rtibiocloud/plink:v1.9_178bb91 plink \
    --file /data/garnet_whi_c1_hg19 \
    --make-bed \
    --out /data/garnet_whi_c1_hg19
```
