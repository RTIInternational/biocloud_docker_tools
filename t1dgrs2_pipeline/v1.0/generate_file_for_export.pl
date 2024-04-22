#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $t1dgrs2_results_file = '';
my $missing_file = '';
my $sample_id = '';
my $hla_variants_file = '';
my $missing_hla_threshold = 1;
my $non_hla_variants_file = '';
my $missing_non_hla_threshold = 3;
my $genedx_manifest_file = '';
my $output_file = '';

GetOptions (
    't1dgrs2_results_file=s' => \$t1dgrs2_results_file,
    'missing_file=s' => \$missing_file,
    'sample_id=s' => \$sample_id,
    'hla_variants_file=s' => \$hla_variants_file,
    'missing_hla_threshold:i' => \$missing_hla_threshold,
    'non_hla_variants_file=s' => \$non_hla_variants_file,
    'missing_non_hla_threshold:i' => \$missing_non_hla_threshold,
    'genedx_manifest_file=s' => \$genedx_manifest_file,
    'output_file=s' => \$output_file
) or die("Invalid options");

my @F;

# Read missing_file
my @missing_variants = ();
open(MISSING, $missing_file);
while (<MISSING>) {
    chomp;
    push(@missing_variants, $_);
}
close MISSING;

# Get counts of missing variants
my $missing_hla_count = 0;
my $missing_non_hla_count = 0;
my $missingness = "FAIL";
if (@missing_variants) {
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

    foreach my $missing_variant (@missing_variants) {
        if (exists($hla_variants{$missing_variant})) {
            $missing_hla_count++;
        } elsif (exists($non_hla_variants{$missing_variant})) {
            $missing_non_hla_count++;
        }
    }
}
if (
    $missing_hla_count < $missing_hla_threshold
    && $missing_non_hla_count < $missing_non_hla_threshold
) { $missingness = "PASS"; }

# Read ID xref from manifest file
my %id_xref = ();
open(MANIFEST, $genedx_manifest_file);
while (<MANIFEST>) {
    chomp;
    @F = split(",");
    $id_xref{$F[0]} = $F[2];
}
close MANIFEST;

# Open output file for writing
open(OUTPUT_FILE, ">".$output_file);
print OUTPUT_FILE join(",", "GeneDx_Accession","RTI_Accession","GRS2","Missing_HLA","Missing_Non_HLA","Missingness_Filter")."\n";

# Process t1dgrs2 results file
open(T1DGRS2_RESULTS, $t1dgrs2_results_file);
<T1DGRS2_RESULTS>;
while(<T1DGRS2_RESULTS>) {
    @F = split("\t");
    if ($F[1] eq $sample_id) {
        if (exists($id_xref{$F[1]})) {
            print OUTPUT_FILE join(",", $F[1], $id_xref{$F[1]}, $F[2], $missing_hla_count, $missing_non_hla_count, $missingness)."\n";
        } else {
            print OUTPUT_FILE join(",", $F[1], "NA", $F[2], $missing_hla_count, $missing_non_hla_count, $missingness)."\n";
        }
    }
}
close T1DGRS2_RESULTS;

close OUTPUT_FILE;
