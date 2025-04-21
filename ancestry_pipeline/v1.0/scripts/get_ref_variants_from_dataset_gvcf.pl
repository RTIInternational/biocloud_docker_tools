#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $fileInGVCF = '';
my $fileInRefBim = '';
my $fileOutPrefix = '';
my $monomorphicPositions = '';

GetOptions (
    'file_in_gvcf=s' => \$fileInGVCF,
    'file_in_ref_bim=s' => \$fileInRefBim,
    'file_out_prefix=s' => \$fileOutPrefix,
    'monomorphic_positions' => \$monomorphicPositions
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

my %variants = ();
my @F = ();

# Read position list
for (my $chr=1; $chr<23; $chr++) {
    %{$variants{"chr".$chr}} = ();
}
open(REF_BIM, $fileInRefBim);
while (<REF_BIM>) {
    chomp;
    @F = split();
    $variants{"chr".$F[0]}{$F[3]} = $F[1];
}
close REF_BIM;

# Get dataset variants by position
open(OUT_VCF, "> $fileOutPrefix.vcf");
open(OUT_VARIANTS, "> ".$fileOutPrefix."_variants.txt");
if ($fileInGVCF =~ /gz$/) {
    open(GVCF, "gunzip -c $fileInGVCF |") or die "gunzip $fileInGVCF: $!";
} else {
    open(GVCF, $fileInGVCF);
}
while(<GVCF>){
    if (/^#/) {
        print OUT_VCF;
    } else {
        chomp;
        @F =split();
        if ($F[6] eq "PASS") {
            if ($F[7] =~ /END=(\d+)/ && ($monomorphicPositions eq 'include')) {
                my $end = $1;
                for (my $i=$F[1]; $i<=$end; $i++) {
                    if (exists($variants{$F[0]})) {
                        if (exists($variants{$F[0]}{$i})) {
                            $variants{$F[0]}{$i} =~ /rs\d+:\d+:(\S+):(\S+)/;
                            my $a1 = $1;
                            my $a2 = $2;
                            my $flipA1 = flip($a1);
                            my $flipA2 = flip($a2);
                            if ($F[3] eq $a1 || $F[3] eq $a2 || $F[3] eq flip($a1) || $F[3] eq flip($a2)) {
                                $F[4] = ($F[3] eq $a1) ? $a2 : (($F[3] eq $a2) ? $a1 : (($F[3] eq $flipA1) ? $flipA2 : $flipA1));
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
                            my $flipA1 = flip($a1);
                            my $flipA2 = flip($a2);
                            if (($F[3] eq $a1 && $F[4] eq $a2) || ($F[3] eq $a2 && $F[4] eq $a1) || ($F[3] eq $flipA1 && $F[4] eq $flipA2) || ($F[3] eq $flipA2 && $F[4] eq $flipA1)) {
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
close GVCF;
close OUT_VCF;
close OUT_VARIANTS;
