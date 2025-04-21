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
my $fileOutDatasetBim = '';
my $fileOutExtractList = '';

GetOptions (
    'file_in_dataset_bim=s' => \$fileInDatasetBim,
    'file_in_ref_bim=s' => \$fileInRefBim,
    'file_out_dataset_bim=s' => \$fileOutDatasetBim,
    'file_out_extract_list=s' => \$fileOutExtractList,
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

# Read variants from ref bim
my %variantIds = ();
my %allele1s = ();
my %allele2s = ();
my %allele1sFlipped = ();   
my %allele2sFlipped = ();
open(REF_BIM, $fileInRefBim);
while (<REF_BIM>) {
    chomp;
    my @F = split();
    my $chrPos = $F[0]."_".$F[3];
    $variantIds{$chrPos} = $F[1];
    $allele1s{$chrPos} = $F[4];
    $allele2s{$chrPos} = $F[5];
    $allele1sFlipped{$chrPos} = flip($F[4]);
    $allele2sFlipped{$chrPos} = flip($F[5]);
}
close REF_BIM;

open(FILE_IN_DATASET_BIM, $fileInDatasetBim);
open(FILE_OUT_DATASET_BIM, "> $fileOutDatasetBim");
open(FILE_OUT_EXTRACT_LIST, "> $fileOutExtractList");
while(<FILE_IN_DATASET_BIM>) {
    chomp;
    my @F = split();
    my $chrPos = $F[0]."_".$F[3];
    if (exists($variantIds{$chrPos})) {
        if (
            ($allele1s{$chrPos} eq $F[4] && $allele2s{$chrPos} eq $F[5]) ||
            ($allele1s{$chrPos} eq $F[5] && $allele2s{$chrPos} eq $F[4]) ||
            ($allele1sFlipped{$chrPos} eq $F[4] && $allele2sFlipped{$chrPos} eq $F[5]) ||
            ($allele1sFlipped{$chrPos} eq $F[5] && $allele2sFlipped{$chrPos} eq $F[4])
        ) {
            $F[1] = $variantIds{$chrPos};
            print FILE_OUT_EXTRACT_LIST $variantIds{$chrPos}."\n";
        }
    }
    print FILE_OUT_DATASET_BIM join("\t", @F)."\n";
}
close FILE_IN_DATASET_BIM;
close FILE_OUT_DATASET_BIM;
close FILE_OUT_EXTRACT_LIST;
