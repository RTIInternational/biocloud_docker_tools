#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $fileInEvec = '';
my $fileInEval = '';
my $fileInSnpWeight = '';
my $fileInBimIdXref= '';
my $fileInFamIdXref= '';
my $fileOutPrefix = '';

GetOptions (
    'file_in_evec=s' => \$fileInEvec,
    'file_in_eval=s' => \$fileInEval,
    'file_in_snpweight=s' => \$fileInSnpWeight,
    'file_in_bim_id_xref=s' => \$fileInBimIdXref,
    'file_in_fam_id_xref=s' => \$fileInFamIdXref,
    'file_out_prefix=s' => \$fileOutPrefix
) or die("Invalid options");

my %bimIdXref = ();
my %famIdXref = ();
my $fileOutEvec = $fileOutPrefix."_evec.tsv";
my $fileOutEval = $fileOutPrefix."_eval.tsv";
my $fileOutSnpWeight = $fileOutPrefix."_snpweight.tsv";
my $junk = '';
my @F = ();

# Read bim ID xref
open(BIM_ID_XREF, $fileInBimIdXref);
while(<BIM_ID_XREF>) {
    /^(\S+)\t(\S+)/;
    $bimIdXref{$1} = $2;
}
close BIM_ID_XREF;

# Read fam ID xref
open(FAM_ID_XREF, $fileInFamIdXref);
while(<FAM_ID_XREF>) {
    /^(\S+)\t(\S+)___(\S+)/;
    $famIdXref{$1.":".$1} = $2."\t".$3;
}
close FAM_ID_XREF;

# evec file
open(FILE_IN_EVEC, $fileInEvec);
open(FILE_OUT_EVEC, "> $fileOutEvec");
print FILE_OUT_EVEC join("\t", "FID", "IID", "PC1", "PC2", "PC3", "PC4", "PC5", "PC6", "PC7", "PC8", "PC9", "PC10", "POP")."\n";
$junk = <FILE_IN_EVEC>;
while (<FILE_IN_EVEC>) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    @F = split(/\s+/);
    print FILE_OUT_EVEC join("\t", $famIdXref{$F[0]}, @F[1..11])."\n";
}
close FILE_IN_EVEC;
close FILE_OUT_EVEC;

# eval file
open(FILE_IN_EVAL, $fileInEval);
open(FILE_OUT_EVAL, "> $fileOutEval");
while (<FILE_IN_EVAL>) {
    /(\S+)/;
    print FILE_OUT_EVAL $1."\n";
}
close FILE_IN_EVAL;
close FILE_OUT_EVAL;

# snpweight file
open(FILE_IN_SNPWEIGHT, $fileInSnpWeight);
open(FILE_OUT_SNPWEIGHT, "> $fileOutSnpWeight");
print FILE_OUT_SNPWEIGHT join("\t", "VARIANT_ID", "CHR", "POS", "PC1", "PC2", "PC3", "PC4", "PC5", "PC6", "PC7", "PC8", "PC9", "PC10")."\n";
$junk = <FILE_IN_SNPWEIGHT>;
while (<FILE_IN_SNPWEIGHT>) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    @F = split(/\s+/);
    print FILE_OUT_SNPWEIGHT join("\t", $bimIdXref{$F[0]}, @F[1..12])."\n";
}
close FILE_IN_SNPWEIGHT;
close FILE_OUT_SNPWEIGHT;
