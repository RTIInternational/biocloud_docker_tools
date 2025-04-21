#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $fileInPsam = '';
my $popType = '';
my $ancestriesToInclude = '';
my $fileOutAncestryIdXref = '';
my $fileOutRefSamples = '';

GetOptions (
    'file_in_psam=s' => \$fileInPsam,
    'pop_type=s' => \$popType,
    'ancestries_to_include=s' => \$ancestriesToInclude,
    'file_out_ancestry_id_xref=s' => \$fileOutAncestryIdXref,
    'file_out_ref_samples=s' => \$fileOutRefSamples,
) or die("Invalid options");

# Set population column to search in PSAM
my $popCol = ($popType eq "SUPERPOP") ? 4 : (($popType eq "POP") ? 5 : 0);

# Create ancestry ID xref
my @ancestries = split(",", $ancestriesToInclude);
my %ancestryIdXref = ();
my $nextAncestryId = 2;
foreach (@ancestries){
    $ancestryIdXref{$_} = $nextAncestryId++;
}

# Write ancestry ID xref to file
open(FILE_OUT_ANCESTRY_ID_XREF, "> $fileOutAncestryIdXref");
print FILE_OUT_ANCESTRY_ID_XREF "$_\t$ancestryIdXref{$_}\n" for (keys %ancestryIdXref);
close FILE_OUT_ANCESTRY_ID_XREF;

# Open ref samples output file
open(FILE_OUT_REF_SAMPLES, "> $fileOutRefSamples");

# Get ref samples
open(PSAM, $fileInPsam);
while(<PSAM>) {
    chomp;
    my @F = split("\t");
    if (exists($ancestryIdXref{$F[$popCol]})) {
        print FILE_OUT_REF_SAMPLES join("\t", "0", $F[0], $ancestryIdXref{$F[$popCol]})."\n";
    }
}

close PSAM;
close FILE_OUT_REF_SAMPLES;
