#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $t1dgrs2_results_file = '';
my $missingness_summary_file = '';
my $out_prefix = '';
my $missing_hla_threshold = 1;
my $missing_non_hla_threshold = 3;

GetOptions (
    't1dgrs2_results_file=s' => \$t1dgrs2_results_file,
    'missingness_summary_file=s' => \$missingness_summary_file,
    'out_prefix=s' => \$out_prefix,
    'missing_hla_threshold:i' => \$missing_hla_threshold,
    'missing_non_hla_threshold:i' => \$missing_non_hla_threshold,
) or die("Invalid options");

my @F;

# Read missingness_summary_file
my %missing_hla_counts = ();
my %missing_non_hla_counts = ();
open(MISSING, $missingness_summary_file);
<MISSING>;
while (<MISSING>) {
    chomp;
    @F = split;
    $missing_hla_counts{$F[0]} = $F[1];
    $missing_non_hla_counts{$F[0]} = $F[2];
}
close MISSING;

# Open sample output file for writing
open(SAMPLE_OUTPUT_FILE, ">".$out_prefix.".csv");
print SAMPLE_OUTPUT_FILE join(",", "RTI_Accession","GRS2","Missingness_Filter")."\n";

# Process t1dgrs2 results file
open(T1DGRS2_RESULTS, $t1dgrs2_results_file);
<T1DGRS2_RESULTS>;
while(<T1DGRS2_RESULTS>) {
    chomp;
    @F = split("\t");
    my $id = $F[0]."_".$F[1];
    my $missingness = "?";
    if (exists($missing_hla_counts{$id})) {
        if (
            $missing_hla_counts{$id} < $missing_hla_threshold
            && $missing_non_hla_counts{$id} < $missing_non_hla_threshold
        ) {
            $missingness = "PASS";
        } else {
            $missingness = "FAIL";
        }
    }
    print SAMPLE_OUTPUT_FILE join(",", $id, $F[2], $missingness)."\n";
}
close T1DGRS2_RESULTS;

close SAMPLE_OUTPUT_FILE;
