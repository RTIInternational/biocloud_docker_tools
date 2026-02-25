#!/usr/bin/perl

# This script is used to extract variants from a gVCF file based on a reference BIM file.
# The script assumes the following:
#   - the gVCF and BIM files are on the same strand
#   - REF allele in the gVCF file is the same as allele 2 in the ref BIM file.
#   - If there are more than 2 alleles for a position in a compressed band, the position will not be extracted
# The script filters the variants based on quality and genotype quality, and outputs the results in VCF format.
# The script takes the following arguments provided via a JSON file:
# --file_in_gvcf: Input gVCF file (can be gzipped)
# --file_in_bim: Input reference BIM file
# --file_out_vcf: Output gVCF file
# --include_homozygous_ref: Include positions that are homozygous for the reference allele (default: 0)
# --filter_by_qual: Filter variants by quality (default: 0)
# --filter_by_gq: Filter variants by genotype quality (default: 0)
# --hom_gq_threshold: Genotype quality threshold for homozygous variants (default: 99)
# --het_gq_threshold: Genotype quality threshold for heterozygous variants (default: 48)
#
# Usage:
# perl extract_gvcf_variants.pl --args <input_gvcf>


use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;
use JSON;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

sub add_variant_to_output {
    my %opt = %{ shift @_ };
    my @F = @{$opt{F}};
    my $OUT_VCF = $opt{OUT_VCF};
    $F[5] = ".";
    $F[7] = ".";
    print $OUT_VCF join("\t", @F)."\n";
}

# Read arguments
my $fileInArgs = '';
GetOptions (
    'args=s' => \$fileInArgs,
) or die("Invalid options");
my $args_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $fileInArgs)
      or die("Can't open \"$fileInArgs\": $!\n");
   local $/;
   <$json_fh>
};
my $json = JSON->new;
my $args = $json->decode($args_text);

my %variants = ();
my @F = ();

# Read position list
open(REF_BIM, $args->{file_in_bim});
while (<REF_BIM>) {
    chomp;
    @F = split();
    $F[0] =~ s/^chr//;
    if (!exists($variants{$F[0]})) {
        %{$variants{$F[0]}} = ();
    }
    if (!exists($variants{$F[0]}{$F[3]})) {
        %{$variants{$F[0]}{$F[3]}} = ();
    }
    if (!exists($variants{$F[0]}{$F[3]}{$F[5]})) {
        %{$variants{$F[0]}{$F[3]}{$F[5]}} = ();
    }
    $variants{$F[0]}{$F[3]}{$F[5]}{$F[4]} = $F[1];
}
close REF_BIM;

# Get gvcf variants by position
open(OUT_VCF, "> ".$args->{file_out_vcf});
if ($args->{file_in_gvcf} =~ /gz$/) {
    open(GVCF, "gunzip -c " . $args->{file_in_gvcf} . " |") or die "gunzip $args->{file_in_gvcf}: $!";
} else {
    open(GVCF, $args->{file_in_gvcf});
}
while(<GVCF>){
    if (/^#CHROM/) {
        chomp;
        @F =split();
        if ($F[9] =~ /^\S+-(\d+)_\d+-WGS/) {
            $F[9] = $1;
        }
        $F[0] =~ s/_/-/g;
        print OUT_VCF join("\t", @F)."\n";
    } elsif (/^#/) {
        print OUT_VCF $_;
    } else {
        chomp;
        @F =split();
        if (
            !$args->{filter_by_qual}
            || (uc($F[6]) eq "PASS")
        ) {
            $F[0] =~ s/^chr//;
            if ($F[0] =~ /^\d+$/) {
                my @keys = split(":", $F[8]);
                my @values = split(":", $F[9]);
                my %variant_data;
                @variant_data{@keys} = @values;
                $variant_data{"GT"} =~ /(\d+|\.).(\d+|\.)/;
                my $a1_index = $1;
                my $a2_index = $2;
                $variant_data{"GT"} =~ s/^(\d+|\.).(\d+|\.)/$a1_index|$a2_index/;
                $F[8] = "GT:GQ";
                $F[9] = join(":", $variant_data{"GT"}, $variant_data{"GQ"});
                if ($a1_index ne "." && $a2_index ne ".") {
                    if (
                        !$args->{filter_by_gq}
                        || (
                            (
                                $a1_index eq $a2_index
                                && ($variant_data{"GQ"} >= $args->{hom_gq_threshold})
                            )
                            || (
                                $a1_index ne $a2_index
                                && ($variant_data{"GQ"} >= $args->{het_gq_threshold})
                            )
                        )
                    ) {
                        if ($F[7] =~ /END=(\d+)/ && $args->{include_homozygous_ref}) {
                            my $end = $1;
                            for (my $i=$F[1]; $i<=$end; $i++) {
                                if (exists($variants{$F[0]}{$i})) {
                                    if (keys(%{$variants{$F[0]}{$i}}) == 1) {
                                        my @position_ref_alleles = keys(%{$variants{$F[0]}{$i}});
                                        my $ref_allele = $position_ref_alleles[0];
                                        if (keys(%{$variants{$F[0]}{$i}{$ref_allele}}) == 1) {
                                            my @position_alt_alleles = keys(%{$variants{$F[0]}{$i}{$ref_allele}});
                                            my $alt_allele = $position_alt_alleles[0];
                                            $F[1] = $i;
                                            $F[2] = $variants{$F[0]}{$i}{$ref_allele}{$alt_allele};
                                            $F[3] = $ref_allele;
                                            $F[4] = $alt_allele;
                                            $F[5] = ".";
                                            $F[7] = ".";
                                            print OUT_VCF join("\t", @F)."\n";
                                        }
                                    }
                                }
                            }
                        } else {
                            my @alleles = ($F[3], split(",", $F[4]));
                            my $ref_allele = $alleles[0];
                            my $alt_allele = "";
                            if (exists($variants{$F[0]}{$F[1]}{$ref_allele})) {
                                if ($a1_index == $a2_index) {
                                    if ($a1_index == 0) {
                                        if (keys(%{$variants{$F[0]}{$F[1]}{$ref_allele}}) == 1) {
                                            my @position_alt_alleles = keys(%{$variants{$F[0]}{$F[1]}{$ref_allele}});
                                            $alt_allele = $position_alt_alleles[0];
                                        } else {
                                            next;
                                        }
                                    } else {
                                        $alt_allele = $alleles[$a1_index];
                                        if (!exists($variants{$F[0]}{$F[1]}{$ref_allele}{$alt_allele})) {
                                            next;
                                        }
                                    }
                                } else {
                                    if ($a1_index == 0 || $a2_index == 0) {
                                        $alt_allele = ($a1_index == 0) ? $alleles[$a2_index] : $alleles[$a1_index];
                                        if (!exists($variants{$F[0]}{$F[1]}{$ref_allele}{$alt_allele})) {
                                            next;
                                        }
                                    } else {
                                        next;
                                    }
                                }
                                $F[2] = $variants{$F[0]}{$F[1]}{$ref_allele}{$alt_allele};
                                $F[3] = $ref_allele;
                                $F[4] = $alt_allele;
                                $F[5] = ".";
                                $F[7] = ".";
                                print OUT_VCF join("\t", @F)."\n";
                            }
                        }
                    }
                }
            }
        }
    }
}
close GVCF;
close OUT_VCF;
