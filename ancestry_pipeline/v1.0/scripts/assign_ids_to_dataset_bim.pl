#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $fileInDatasetBim = '';
my $fileInRefBim = '';
my $fileOutPrefix = '';

GetOptions (
    'file_in_dataset_bim=s' => \$fileInDatasetBim,
    'file_in_ref_bim=s' => \$fileInRefBim,
    'file_out_prefix=s' => \$fileOutPrefix
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

# Get list of variants in dataset
my %datasetPositions = ();
open(FILE_IN_DATASET_BIM, $fileInDatasetBim);
while(<FILE_IN_DATASET_BIM>) {
    chomp;
    my @F = split();
    my $chrPos = $F[0]."_".$F[3];
    $datasetPositions{$F[0]."_".$F[3]} = 1;
}
close FILE_IN_DATASET_BIM;

# Read variants from ref bim
my %variantIds = ();
my %allele1s = ();
my %allele2s = ();
open(REF_BIM, $fileInRefBim);
while (<REF_BIM>) {
    chomp;
    my @F = split();
    my $chrPos = $F[0]."_".$F[3];
    if (exists($datasetPositions{$chrPos})) {
        $variantIds{$chrPos} = $F[1];
        $allele1s{$chrPos} = $F[4];
        $allele2s{$chrPos} = $F[5];
    }
}
close REF_BIM;

open(FILE_IN_DATASET_BIM, $fileInDatasetBim);
open(FILE_OUT_DATASET_BIM, "> ".$fileOutPrefix.".bim");
open(FILE_OUT_EXTRACT_LIST, "> ".$fileOutPrefix."_extract.txt");
open(FILE_OUT_FLIP_LIST, "> ".$fileOutPrefix."_flip.txt");
while(<FILE_IN_DATASET_BIM>) {
    chomp;
    my @F = split();
    my $chrPos = $F[0]."_".$F[3];
    if (exists($variantIds{$chrPos})) {
        my $rcAllele1 = flip($F[4]);
        my $rcAllele2 = flip($F[5]);
        if (
            ($allele1s{$chrPos} eq $F[4] && $allele2s{$chrPos} eq $F[5]) ||
            ($allele1s{$chrPos} eq $F[5] && $allele2s{$chrPos} eq $F[4]) ||
            ($allele1s{$chrPos} eq $rcAllele1 && $allele2s{$chrPos} eq $rcAllele2) ||
            ($allele1s{$chrPos} eq $rcAllele2 && $allele2s{$chrPos} eq $rcAllele1)
        ) {
            $F[1] = $variantIds{$chrPos};
            print FILE_OUT_EXTRACT_LIST $variantIds{$chrPos}."\n";
            if (
                ($allele1s{$chrPos} eq $rcAllele1 && $allele2s{$chrPos} eq $rcAllele2) ||
                ($allele1s{$chrPos} eq $rcAllele2 && $allele2s{$chrPos} eq $rcAllele1)
            ) {
                print FILE_OUT_FLIP_LIST $variantIds{$chrPos}."\n";
            }
        }
    }
    print FILE_OUT_DATASET_BIM join("\t", @F)."\n";
}
close FILE_IN_DATASET_BIM;
close FILE_OUT_DATASET_BIM;
close FILE_OUT_EXTRACT_LIST;
close FILE_OUT_FLIP_LIST;
