#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $fileInDatasetFam = '';
my $fileInRefFam = '';
my $fileInRefSamples = '';
my $fileOutDatasetFam = '';
my $fileOutRefFam = '';

GetOptions (
    'file_in_dataset_fam=s' => \$fileInDatasetFam,
    'file_in_ref_fam=s' => \$fileInRefFam,
    'file_in_ref_samples=s' => \$fileInRefSamples,
    'file_out_dataset_fam=s' => \$fileOutDatasetFam,
    'file_out_ref_fam=s' => \$fileOutRefFam,
);

# Process dataset fam
open(FILE_IN_DATASET_FAM, $fileInDatasetFam);
open(FILE_OUT_DATASET_FAM, "> $fileOutDatasetFam");
while(<FILE_IN_DATASET_FAM>) {
    chomp;
    my @F = split(/\s/);
    print FILE_OUT_DATASET_FAM join("\t",@F[0..4],"1")."\n";
}
close FILE_IN_DATASET_FAM;
close FILE_OUT_DATASET_FAM;

# Read ref sample xref
my %ref_sample_xref = ();
open(REF_SAMPLES, $fileInRefSamples);
while(<REF_SAMPLES>) {
    chomp;
    my @F = split(/\s/);
    $ref_sample_xref{$F[0]."_".$F[1]} = $F[2];
}
close REF_SAMPLES;

# Process ref fam
open(FILE_IN_REF_FAM, $fileInRefFam);
open(FILE_OUT_REF_FAM, "> $fileOutRefFam");
while(<FILE_IN_REF_FAM>) {
    chomp;
    my @F = split(/\s/);
    if (exists($ref_sample_xref{$F[0]."_".$F[1]})) {
        print FILE_OUT_REF_FAM join("\t", @F[0..4], $ref_sample_xref{$F[0]."_".$F[1]})."\n";
    } else {
        print FILE_OUT_REF_FAM join("\t", @F)."\n";
    }
}
close FILE_IN_REF_FAM;
close FILE_OUT_REF_FAM;
