<details>
<summary>Create variant list for extract_gvcf_variants.pl</summary>

``` shell
for chr in {1..22}; do
    gunzip -c /rti-01/ngaddis/data/rti-common/genomes/human/grch37/chr$chr.fa.gz |
        tail -n +2 |
        perl -lne '
            use warnings;
            BEGIN {
                $line = 0;
                $pos = 1;
            }
            chomp;
            s/\r//;
            @seq = split(//);
            for ($i=$pos; $i<($pos + @seq); $i++) {
                $hg19Ref = uc($seq[$i - 1 - ($line * 50)]);
                if ($hg19Ref ne "N") {
                    print "'$chr':$i"."\t".$hg19Ref;
                }
            }
            $line++;
            $pos += 50;
        '
done > ~/data/temp/ancestry_pipeline/hg19_ref_alleles.tsv
gzip ~/data/temp/ancestry_pipeline/hg19_ref_alleles.tsv.gz

gunzip -c /rti-01/ngaddis/data/temp/ancestry_pipeline/hg19_ref_alleles.tsv.gz |
    perl -lane '
        BEGIN {
            %a1s = ();
            %a2s = ();
            %rsids = ();
            open(BIM, "/rti-01/ngaddis/data/temp/ancestry_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bim");
            while (<BIM>){
                chomp;
                @fields = split("\t");
                $chrPos = $fields[0].":".$fields[3];
                $a1s{$chrPos} = $fields[4];
                $a2s{$chrPos} = $fields[5];
                $rsids{$chrPos} = $fields[1];
            }
            close BIM;
            sub flip {
                my ($allele) = @_;
                my $alleleComplement = "";
                my %flipMap = (
                    "A" => "T",
                    "T" => "A",
                    "C" => "G",
                    "G" => "C",
                    "-" => "-"
                );
                foreach my $nt (reverse(split("", $allele))) {
                    if (!exists($flipMap{uc($nt)})) {
                        $alleleComplement = $allele;
                        last;
                    } else {
                        $alleleComplement .= $flipMap{uc($nt)};
                    }
                }
                return $alleleComplement;
            }
        }
        if (exists($rsids{$F[0]})) {
            if ($a1s{$F[0]} eq $F[1]) {
                print join("\t", $F[0], $rsids{$F[0]}, $a1s{$F[0]}, $a2s{$F[0]});
            } elsif ($a2s{$F[0]} eq $F[1]) {
                print join("\t", $F[0], $rsids{$F[0]}, $a2s{$F[0]}, $a1s{$F[0]});
            } elsif (flip($a1s{$F[0]}) eq $F[1]) {
                print join("\t", $F[0], $rsids{$F[0]}, flip($a1s{$F[0]}), flip($a2s{$F[0]}));
            } elsif (flip($a2s{$F[0]}) eq $F[1]) {
                print join("\t", $F[0], $rsids{$F[0]}, flip($a2s{$F[0]}), flip($a1s{$F[0]}));
            }
        }
    ' > ~/data/temp/ancestry_pipeline/1000g_ld_pruned.tsv
gzip ~/data/temp/ancestry_pipeline/1000g_ld_pruned.tsv

# Transfer to /home/merge-shared-folder/ancestry_pipeline_runs/pipeline_inputs/
```
</details>

<details>
<summary>LD prune hg19 1000G reference genotypes</summary>

``` shell
# Download ref files
for ext in bed bim fam; do
    aws s3 cp s3://rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/all_phase3_unique_grch37_dbsnp_b153.$ext \
        ~/data/rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/
done
aws s3 cp s3://rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/phase3_orig.psam \
    ~/data/rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/
aws s3 cp s3://rti-common/linkage_disequilibrium/regions_of_high_ld_for_pca_wdl_wf_hg19.bed \
    ~/data/rti-common/linkage_disequilibrium/

# Remove non-rsID and A/T, C/G variants
perl -lane '
    chomp;
    if ($F[1] =~ /^rs/) {
        if (!(($F[4] eq "A" && $F[5] eq "T") || ($F[4] eq "T" && $F[5] eq "A") || ($F[4] eq "C" && $F[5] eq "G") || ($F[4] eq "G" && $F[5] eq "C"))) {
            if (length($F[4]) == 1 and length($F[5]) == 1) {
                print $F[1];
            }
        }
    }
' ~/data/rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/all_phase3_unique_grch37_dbsnp_b153.bim > \
    ~/data/temp/ancestry_pipeline/all_phase3_unique_grch37_dbsnp_b153_rsids.txt

docker run -ti -v /rti-01/ngaddis:/mnt --rm rtibiocloud/plink:v2.0_c6004f7 bash

# LD prune
plink2 \
    --bfile /mnt/data/rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/all_phase3_unique_grch37_dbsnp_b153 \
    --indep-pairwise 20000 2000 0.5  \
    --maf 0.01 \
    --exclude range /mnt/data/rti-common/linkage_disequilibrium/regions_of_high_ld_for_pca_wdl_wf_hg19.bed \
    --extract /mnt/data/temp/ancestry_pipeline/all_phase3_unique_grch37_dbsnp_b153_rsids.txt \
    --out /mnt/data/temp/ancestry_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld \
    --threads 8

# Extract LD-pruned variants
plink2 \
    --bfile /mnt/data/rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/all_phase3_unique_grch37_dbsnp_b153 \
    --out /mnt/data/temp/ancestry_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned \
    --make-bed \
    --threads 8 \
    --extract /mnt/data/temp/ancestry_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld.prune.in

# Get list of chr, pos, ID for ld pruned variants
perl -lane 'print join("\t",$F[0], $F[3], $F[1]);' ~/data/temp/ancestry_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned.bim > \
    ~/data/temp/ancestry_pipeline/all_phase3_unique_grch37_dbsnp_b153_ld_pruned_variants.tsv

# Transfer to /home/merge-shared-folder/ancestry_pipeline_runs/pipeline_inputs/
# Transfer s3://rti-common/ref_panels/mis/1000g/phase3/2.0.0/plink/phase3_orig.psam to /home/merge-shared-folder/ancestry_pipeline_runs/pipeline_inputs/
```
</details>
