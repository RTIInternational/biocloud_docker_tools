#!/usr/bin/perl

# This script is used to extract variants from a gVCF file based on a reference BIM file.
# The script assumes that both the gVCF and BIM files are on the same strand.
# It also assumes that the BIM file does not contain A/T or C/G SNPs.
# It filters the variants based on quality and genotype quality, and outputs the results in VCF format.
# The script takes the following command line arguments:
# --file_in_gvcf: Input gVCF file (can be gzipped)
# --file_in_ref_bim: Input reference BIM file
# --file_out_prefix: Output prefix for the VCF and variants files
# --include_monomorphic_positions: Include monomorphic positions in the output (default: 0)
# --filter_by_qual: Filter variants by quality (default: 0)
# --filter_by_gq: Filter variants by genotype quality (default: 0)
# --hom_gq_threshold: Genotype quality threshold for homozygous variants (default: 99)
# --het_gq_threshold: Genotype quality threshold for heterozygous variants (default: 48)
#
# Usage:
# perl get_ref_variants_from_dataset_gvcf.pl --file_in_gvcf <input_gvcf> --file_in_ref_bim <input_bim> --file_out_prefix <output_prefix> [options]
# Example:
# perl get_ref_variants_from_dataset_gvcf.pl --file_in_gvcf input.gvcf.gz --file_in_ref_bim ref.bim --file_out_prefix output_prefix --include_monomorphic_positions 1 --filter_by_qual 1 --filter_by_gq 1 --hom_gq_threshold 99 --het_gq_threshold 48


use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $file_in_gvcf = '';
my $file_in_ref_bim = '';
my $file_out_prefix = '';
my $include_monomorphic_positions = 0;
my $filter_by_qual = 0;
my $filter_by_gq = 0;
my $hom_gq_threshold = 99;
my $het_gq_threshold = 48;

GetOptions (
    'file_in_gvcf=s' => \$file_in_gvcf,
    'file_in_ref_bim=s' => \$file_in_ref_bim,
    'file_out_prefix=s' => \$file_out_prefix,
    'include_monomorphic_positions:i' => \$include_monomorphic_positions,
    'filter_by_qual:i' => \$filter_by_qual,
    'filter_by_gq:i' => \$filter_by_gq,
    'hom_gq_threshold:i' => \$hom_gq_threshold,
    'het_gq_threshold:i' => \$het_gq_threshold
) or die("Invalid options");

sub add_variant_to_output {
    my %opt = %{ shift @_ };
    my @F = @{$opt{F}};
    my $OUT_VCF = $opt{OUT_VCF};
    my $OUT_VARIANTS = $opt{OUT_VARIANTS};
    $F[7] = "";
    $F[8] =~ s/:.+//;
    $F[9] =~ s/:.+//;
    print $OUT_VCF join("\t", @F)."\n";
    print $OUT_VARIANTS $F[2]."\n";
}

my %variants = ();
my @F = ();

# Read position list
for (my $chr=1; $chr<23; $chr++) {
    %{$variants{"chr".$chr}} = ();
}
open(REF_BIM, $file_in_ref_bim);
while (<REF_BIM>) {
    chomp;
    @F = split();
    $variants{"chr".$F[0]}{$F[3]} = $F[1];
}
close REF_BIM;

# Get dataset variants by position
open(OUT_VCF, "> ".$file_out_prefix.".vcf");
open(OUT_VARIANTS, "> ".$file_out_prefix."_variants.txt");
if ($file_in_gvcf =~ /gz$/) {
    open(GVCF, "gunzip -c $file_in_gvcf |") or die "gunzip $file_in_gvcf: $!";
} else {
    open(GVCF, $file_in_gvcf);
}
while(<GVCF>){
    if (/^#/) {
        print OUT_VCF;
    } else {
        chomp;
        @F =split();
        if (
            !$filter_by_qual
            || (uc($F[6]) eq "PASS")
        ) {
            if ($F[0] =~ /(\d+)$/) {
                my $chr = $1;
                my @keys = split(":", $F[8]);
                my @values = split(":", $F[9]);
                my %variant_data;
                @variant_data{@keys} = @values;
                $variant_data{"GT"} =~ /(\d+|\.).(\d+|\.)/;
                my $sample_a1_index = $1;
                my $sample_a2_index = $2;
                $F[9] =~ s/^(\d+|\.).(\d+|\.)/$sample_a1_index|$sample_a2_index/;
                if (
                    !$filter_by_gq
                    || (
                        (
                            $sample_a1_index eq $sample_a2_index
                            && ($variant_data{"GQ"} >= $hom_gq_threshold)
                        )
                        || (
                            $sample_a1_index ne $sample_a2_index
                            && ($variant_data{"GQ"} >= $het_gq_threshold)
                        )
                    )
                ) {
                    if ($F[7] =~ /END=(\d+)/ && $include_monomorphic_positions) {
                        my $end = $1;
                        for (my $i=$F[1]; $i<=$end; $i++) {
                            if (exists($variants{$F[0]})) {
                                if (exists($variants{$F[0]}{$i})) {
                                    $variants{$F[0]}{$i} =~ /rs\d+:\d+:(\S+):(\S+)/;
                                    my $a1 = $1;
                                    my $a2 = $2;
                                    if ($F[3] eq $a1 || $F[3] eq $a2) {
                                        $F[4] = ($F[3] eq $a1) ? $a2 : $a1;
                                        $F[1] = $i;
                                        $F[2] = $variants{$F[0]}{$i};
                                        add_variant_to_output({F=>\@F, OUT_VCF=>\*OUT_VCF, OUT_VARIANTS=>\*OUT_VARIANTS});
                                    }
                                }
                            }
                        }
                    } else {
                        if (exists($variants{$F[0]})) {
                            if (exists($variants{$F[0]}{$F[1]})) {
                                $F[4] =~ s/,<NON_REF>//;
                                if ($F[4] !~ /,/) {
                                    $variants{$F[0]}{$F[1]} =~ /rs\d+:\d+:(\S+):(\S+)/;
                                    my $a1 = $1;
                                    my $a2 = $2;
                                    if (($F[3] eq $a1 && $F[4] eq $a2) || ($F[3] eq $a2 && $F[4] eq $a1)) {
                                        $F[2] = $variants{$F[0]}{$F[1]};
                                        add_variant_to_output({F=>\@F, OUT_VCF=>\*OUT_VCF, OUT_VARIANTS=>\*OUT_VARIANTS});
                                    }
                                }
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
close OUT_VARIANTS;

# Create empty flip file
open(OUT_FLIP, "> ".$file_out_prefix."_flip.txt");
close OUT_FLIP;
