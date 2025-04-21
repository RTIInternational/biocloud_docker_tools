#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $fileInBed = '';
my $fileInBim = '';
my $fileInFam = '';
my $fileInPopIdXref = '';
my $datasetName = '';
my $refPops = '';
my $fileOutPrefix = '';
my $smartpcaOutPrefix = '';

GetOptions (
    'file_in_bed=s' => \$fileInBed,
    'file_in_bim=s' => \$fileInBim,
    'file_in_fam=s' => \$fileInFam,
    'file_in_pop_id_xref=s' => \$fileInPopIdXref,
    'dataset_name=s' => \$datasetName,
    'ref_pops=s' => \$refPops,
    'file_out_prefix=s' => \$fileOutPrefix,
    'smartpca_out_prefix=s' => \$smartpcaOutPrefix
) or die("Invalid options");

my $nextId = 1;
my $id = "";
my @F = ();
my %popIdXref = ();

# Process bim
open(FILE_IN_BIM, $fileInBim);
open(FILE_OUT_BIM, "> $fileOutPrefix.bim");
open(FILE_OUT_BIM_XREF, "> ".$fileOutPrefix."_bim_xref.tsv");
while(<FILE_IN_BIM>) {
    chomp;
    @F = split(/\s/);
    $id = "ID_".$nextId++;
    print FILE_OUT_BIM_XREF join("\t",$id,$F[1])."\n";
    print FILE_OUT_BIM join("\t",$F[0],$id,@F[2..5])."\n";
}
close FILE_IN_BIM;
close FILE_OUT_BIM;
close FILE_OUT_BIM_XREF;

# Load population names
$popIdXref{"1"} = $datasetName;
open(POP_ID_XREF, $fileInPopIdXref);
while(<POP_ID_XREF>) {
    chomp;
    @F = split;
    $popIdXref{$F[1]} = $F[0];
}
close POP_ID_XREF;

# Process fam
open(FILE_IN_FAM, $fileInFam);
open(FILE_OUT_FAM, "> $fileOutPrefix.fam");
open(FILE_OUT_FAM_XREF, "> ".$fileOutPrefix."_fam_xref.tsv");
$nextId = 1;
while(<FILE_IN_FAM>) {
    chomp;
    @F = split(/\s/);
    $id = "ID_".$nextId++;
    print FILE_OUT_FAM_XREF join("\t",$id,$F[0]."___".$F[1])."\n";
    print FILE_OUT_FAM join("\t",$id,$id,@F[2..4],$popIdXref{$F[5]})."\n";
}
close FILE_IN_FAM;
close FILE_OUT_FAM;
close FILE_OUT_FAM_XREF;

# Create pop list
open(FILE_OUT_POP_LIST, "> ".$fileOutPrefix."_pop_list.tsv");
foreach my $pop (split(",", $refPops)) {
    print FILE_OUT_POP_LIST $pop."\n";
}
close FILE_OUT_POP_LIST;

# Create parameter file
open(FILE_OUT_PAR, "> ".$fileOutPrefix."_par.txt");
print FILE_OUT_PAR "genotypename: $fileInBed\n";
print FILE_OUT_PAR "snpname: $fileOutPrefix.bim\n";
print FILE_OUT_PAR "indivname: $fileOutPrefix.fam\n";
print FILE_OUT_PAR "poplistname: ".$fileOutPrefix."_pop_list.tsv\n";
print FILE_OUT_PAR "evecoutname: $smartpcaOutPrefix.evec\n";
print FILE_OUT_PAR "evaloutname: $smartpcaOutPrefix.eval\n";
print FILE_OUT_PAR "snpweightoutname: $smartpcaOutPrefix.snpweight\n";
print FILE_OUT_PAR "altnormstyle: YES\n";
print FILE_OUT_PAR "numoutevec: 10\n";
print FILE_OUT_PAR "numoutlieriter: 5\n";
close FILE_OUT_PAR;
