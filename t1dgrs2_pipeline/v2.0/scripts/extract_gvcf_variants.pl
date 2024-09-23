#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $sample_id = '';
my $gvcf = '';
my $variant_list = '';
my $hla_variants_file = '';
my $non_hla_variants_file = '';
my $out_prefix;
my $pass_only = 0;
my $filter_by_gq = 0;
my $hom_gq_threshold = 99;
my $het_gq_threshold = 48;

GetOptions (
    'sample_id=s' => \$sample_id,
    'gvcf=s' => \$gvcf,
    'variant_list=s' => \$variant_list,
    'hla_variants_file' => \$hla_variants_file,
    'non_hla_variants_file' => \$non_hla_variants_file,
    'out_prefix=s' => \$out_prefix,
    'pass_only:i' => \$pass_only,
    'filter_by_gq:i' => \$filter_by_gq,
    'hom_gq_threshold:i' => \$hom_gq_threshold,
    'het_gq_threshold:i' => \$het_gq_threshold,
) or die("Invalid options");

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

my %variantIds = ();
my %refAlleles = ();
my %altAlleles = ();
my @F = ();

# Read extract file
if ($variant_list =~ /gz$/) {
    open(EXTRACT, "gunzip -c $variant_list |") or die "gunzip $variant_list: $!";
} else {
    open(EXTRACT, $variant_list);
}
while (<EXTRACT>) {
    chomp;
    @F = split();
    $variantIds{$F[0]} = $F[1] ? $F[1] : (join(":", $F[0], $F[2], $F[3]));
    $refAlleles{$F[0]} = $F[2];
    $altAlleles{$F[0]} = $F[3];
}
close EXTRACT;

# Get dataset variants by position
open(OUT_VCF, "> ".$out_prefix.".vcf");
if ($gvcf =~ /gz$/) {
    open(GVCF, "gunzip -c $gvcf |") or die "gunzip $gvcf: $!";
} else {
    open(GVCF, $gvcf);
}
print "Extracting " . keys(%variantIds). " variants from $gvcf...\n";
while(<GVCF>){
    if (/^#/) {
        print OUT_VCF;
    } else {
        chomp;
        @F =split("\t");
        if (
            !$pass_only
            || (uc($F[6]) eq "PASS")
        ) {
            if ($F[0] =~ /(\d+)$/) {
                my $chr = $1;
                my @keys = split(":", $F[8]);
                my @values = split(":", $F[9]);
                my %variantData;
                @variantData{@keys} = @values;
                $variantData{"GT"} =~ /(\d+|\.).(\d+|\.)/;
                my $sampleA1Index = $1;
                my $sampleA2Index = $2;
                $F[9] =~ s/^(\d+|\.).(\d+|\.)/$sampleA1Index|$sampleA2Index/;
                if (
                    !$filter_by_gq
                    || (
                        (
                            $sampleA1Index eq $sampleA2Index
                            && ($variantData{"GQ"} >= $hom_gq_threshold)
                        )
                        || (
                            $sampleA1Index ne $sampleA2Index
                            && ($variantData{"GQ"} >= $het_gq_threshold)
                        )
                    )
                ) {
                    if ($F[7] =~ /END=(\d+)/) {
                        my $end = $1;
                        for (my $i=$F[1]; $i<=$end; $i++) {
                            my $chrPos = $chr.":".$i;
                            if (exists($refAlleles{$chrPos})) {
                                print OUT_VCF join("\t", $chr, $i, $variantIds{$chrPos}, $refAlleles{$chrPos}, $altAlleles{$chrPos}, @F[5..6], ".", $F[8], $F[9])."\n";
                                delete($refAlleles{$chrPos});
                            }
                        }
                    } else {
                        my $chrPos = $chr.":".$F[1];
                        if (exists($refAlleles{$chrPos}) && $F[3] eq $refAlleles{$chrPos}) {
                            my %sampleAlleles = ();
                            $sampleAlleles{'0'} = 1;
                            $sampleAlleles{$sampleA1Index} = 1;
                            $sampleAlleles{$sampleA2Index} = 1;
                            if (keys(%sampleAlleles) < 3) {
                                my @alleles =($F[3]);
                                push(@alleles, split(",", $F[4]));
                                if (@alleles == 3) {
                                    $F[4] = $alleles[1];
                                } else {
                                    if ($sampleA2Index != 0) {
                                        $F[4] = $alleles[$sampleA2Index];
                                    } elsif ($sampleA1Index != 0) {
                                        $F[4] = $alleles[$sampleA1Index];
                                    }
                                }
                                if ($F[4] eq $altAlleles{$chrPos}) {
                                    print OUT_VCF join("\t", $chr, $F[1], $variantIds{$chrPos}, @F[3..9])."\n";
                                    delete($refAlleles{$chrPos});
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

# Write list of missing positions
my @missing = sort(keys(%refAlleles));
if (@missing > 0) {
    print "Missing variants:\n"
}
open(OUT_MISSING, "> ".$out_prefix."_missing.txt");
foreach my $position (@missing) {
    print OUT_MISSING $variantIds{$position}."\n";
    print $variantIds{$position}."\n";
}
close OUT_MISSING;

# Write missingness summary
my $missing_hla_count = 0;
my $missing_non_hla_count = 0;
if (@missing) {
    # Read HLA variants
    my %hla_variants = ();
    open(HLA, $hla_variants_file);
    while (<HLA>) {
        chomp;
        $hla_variants{$_} = 1;
    }
    close HLA;

    # Read non-HLA variants
    my %non_hla_variants = ();
    open(NON_HLA, $non_hla_variants_file);
    while (<NON_HLA>) {
        chomp;
        $non_hla_variants{$_} = 1;
    }
    close NON_HLA;

    foreach my $missing_variant (@missing) {
        if (exists($hla_variants{$missing_variant})) {
            $missing_hla_count++;
        } elsif (exists($non_hla_variants{$missing_variant})) {
            $missing_non_hla_count++;
        }
    }
}
open(OUT_MISSING_SUMMARY, "> ".$out_prefix."_missing_summary.tsv");
print OUT_MISSING_SUMMARY join("\t", "SAMPLE_ID", "MISSING_HLA_COUNT", "MISSING_NON_HLA_COUNT");
print OUT_MISSING_SUMMARY join("\t", $sample_id, $missing_hla_count, $missing_non_hla_count);
close OUT_MISSING_SUMMARY;

print "\nExtraction complete\n"
