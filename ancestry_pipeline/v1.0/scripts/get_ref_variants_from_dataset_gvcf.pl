#!/usr/bin/perl

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
my $monomorphic_positions = 'exclude';
my $pass_only = 0;
my $filter_by_gq = 0;
my $hom_gq_threshold = 99;
my $het_gq_threshold = 48;

GetOptions (
    'file_in_gvcf=s' => \$file_in_gvcf,
    'file_in_ref_bim=s' => \$file_in_ref_bim,
    'file_out_prefix=s' => \$file_out_prefix,
    'monomorphic_positions:s' => \$monomorphic_positions,
    'pass_only:i' => \$pass_only,
    'filter_by_gq:i' => \$filter_by_gq,
    'hom_gq_threshold:i' => \$hom_gq_threshold,
    'het_gq_threshold:i' => \$het_gq_threshold
) or die("Invalid options");

sub flip {
    my ($allele) = @_;
    my $allele_complement = "";
    my %flipMap = (
        "A" => "T",
        "T" => "A",
        "C" => "G",
        "G" => "C",
        "-" => "-"
    );
    foreach my $nt (reverse(split("", $allele))) {
        if (!exists($flipMap{uc($nt)})) {
            $allele_complement = $allele;
            last;
        } else {
            $allele_complement .= $flipMap{uc($nt)};
        }
    }
    return $allele_complement;
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
open(OUT_VCF, "> $file_out_prefix.vcf");
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
            !$pass_only
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
                    if ($F[7] =~ /END=(\d+)/ && ($monomorphic_positions eq 'include')) {
                        my $end = $1;
                        for (my $i=$F[1]; $i<=$end; $i++) {
                            if (exists($variants{$F[0]})) {
                                if (exists($variants{$F[0]}{$i})) {
                                    $variants{$F[0]}{$i} =~ /rs\d+:\d+:(\S+):(\S+)/;
                                    my $a1 = $1;
                                    my $a2 = $2;
                                    my $flip_a1 = flip($a1);
                                    my $flip_a2 = flip($a2);
                                    if ($F[3] eq $a1 || $F[3] eq $a2 || $F[3] eq flip($a1) || $F[3] eq flip($a2)) {
                                        $F[4] = ($F[3] eq $a1) ? $a2 : (($F[3] eq $a2) ? $a1 : (($F[3] eq $flip_a1) ? $flip_a2 : $flip_a1));
                                        $F[7] = "END=".$i;
                                        print OUT_VCF join("\t", $F[0], $i, $variants{$F[0]}{$i}, @F[3..(@F-1)])."\n";
                                        print OUT_VARIANTS $variants{$F[0]}{$i}."\n";
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
                                    my $flip_a1 = flip($a1);
                                    my $flip_a2 = flip($a2);
                                    if (($F[3] eq $a1 && $F[4] eq $a2) || ($F[3] eq $a2 && $F[4] eq $a1) || ($F[3] eq $flip_a1 && $F[4] eq $flip_a2) || ($F[3] eq $flip_a2 && $F[4] eq $flip_a1)) {
                                        print OUT_VCF join("\t", $F[0], $F[1], $variants{$F[0]}{$F[1]}, @F[3..(@F-1)])."\n";
                                        print OUT_VARIANTS $variants{$F[0]}{$F[1]}."\n";
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
