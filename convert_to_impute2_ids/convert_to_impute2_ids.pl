#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

# Assign defaults for legend columns
my $legendIdCol = 0;
my $legendChrCol = 1;
my $legendPosCol = 2;
my $legendA1Col = 3;
my $legendA2Col = 4;

my $fileIn = '';
my $fileOut = '';
my $legend = '';
my $fileInHeader = -1;
my $fileInIdCol = -1;
my $fileInChrCol = -1;
my $fileInPosCol = -1;
my $fileInA1Col = -1;
my $fileInA2Col = -1;
my $fileInMonomorphicAllele = "";

GetOptions (
    'file_in=s' => \$fileIn,
    'file_in_header=i' => \$fileInHeader,
    'file_in_id_col=i' => \$fileInIdCol,
    'file_in_chr_col=i' => \$fileInChrCol,
    'file_in_pos_col=i' => \$fileInPosCol,
    'file_in_a1_col=i' => \$fileInA1Col,
    'file_in_a2_col=i' => \$fileInA2Col,
    'file_in_monomorphic_allele=s' => \$fileInMonomorphicAllele,
    'legend_with_chr=s' => \$legend,
    'file_out=s' => \$fileOut,
);

if ($fileIn eq '') { die "Please provide an input file\n"; }
if ($fileInIdCol eq -1) { die "Please provide the ID column in the input file\n"; }
if ($fileInChrCol eq -1) { die "Please provide the chromosome column in the input file\n"; }
if ($fileInPosCol eq -1) { die "Please provide the position column in the input file\n"; }
if ($fileInA1Col eq -1) { die "Please provide the allele 1 column in the input file\n"; }
if ($fileInA2Col eq -1) { die "Please provide the allele 2 column in the input file\n"; }
if ($fileInMonomorphicAllele eq '') { die "Please provide the monomorphic allele code used in the input file\n"; }
if ($legend eq '') { die "Please provide a legend file\n"; }
if ($fileOut eq '') { die "Please provide an output file\n"; }

sub flip {

    my ($allele, $monomorphicAllele) = @_;
    my $alleleComplement = "";

    if (uc($allele) eq uc($monomorphicAllele)) {

        $alleleComplement = $allele;

    } else {

        my %flipMap = (
            "A" => "T",
            "T" => "A",
            "C" => "G",
            "G" => "C",
            "-" => "-"
        );

        foreach my $nt (reverse(split("", $allele))) {
            if (!exists($flipMap{uc($nt)})) {
                $alleleComplement = "error";
                last;
            } else {
                $alleleComplement .= $flipMap{uc($nt)};
            }
        }

    }

    return $alleleComplement;

}

my %xChr = (
    "23" => 1,
    "25" => 1,
    "X" => 1,
    "XY" => 1,
    "X_NONPAR" => 1,
    "X_PAR" => 1,
    "X_PAR1" => 1,
    "X_PAR2" => 1
);
my %variants = ();
my %positionVariantCount = ();
my %rsIndels = ();
my %ridAlleles = (
    'R' => 1,
    'I' => 1,
    'D' => 1
);
my %indelRegExPatterns = (
    '<DEL>' => 1,
    '^!.*' => 1,
    'NA' => 1
);
if (exists($indelRegExPatterns{$fileInMonomorphicAllele})) {
    delete $indelRegExPatterns{$fileInMonomorphicAllele};
}

# Read legend file
print "Reading legend file...\n";
if ($legend =~ /\.gz$/) {
    open(LEGEND, "gunzip -c $legend |") or die "Cannot open ".$legend."\n";
} else {
    open(LEGEND, $legend) or die "Cannot open ".$legend."\n";
}
my $junk = <LEGEND>;
while (<LEGEND>) {

    chomp;
    my @F = split;

    # Convert alleles to uppercase
    $F[$legendA1Col] = uc($F[$legendA1Col]);
    $F[$legendA2Col] = uc($F[$legendA2Col]);

    # Increment count for position of variant by 1 in %positionVariantCount
    if (exists($positionVariantCount{$F[$legendPosCol]})) {
        $positionVariantCount{$F[$legendPosCol]}++;
    } else {
        $positionVariantCount{$F[$legendPosCol]} = 1;
    }

    # Add variant to %variants
    $variants{join('_', $F[$legendChrCol], $F[$legendPosCol], $F[$legendA1Col], $F[$legendA2Col])} = $F[$legendIdCol];

    # Add monomorphic versions of variants to %variants
    $variants{join('_', $F[$legendChrCol], $F[$legendPosCol], $F[$legendA1Col], $fileInMonomorphicAllele)} = $F[$legendIdCol];
    $variants{join('_', $F[$legendChrCol], $F[$legendPosCol], $F[$legendA2Col], $fileInMonomorphicAllele)} = $F[$legendIdCol];

    # If an indel, add an entry for the alternative notation that uses "-" for one of the alleles to %variants
    if ($F[5] eq 'Biallelic_INDEL' || ($F[5] eq 'Multiallelic_INDEL' && (length($F[$legendA1Col]) == 1 || length($F[$legendA2Col]) == 1))) {
        my @alleles = (
            $F[$legendA1Col],
            $F[$legendA2Col]
        );
        foreach my $allele (@alleles) {
            $allele =~ s/^.//;
            $allele = ($allele eq '') ? '-' : $allele;
        }
        $variants{join('_', $F[$legendChrCol], ($F[$legendPosCol] + 1), @alleles)} = $F[$legendIdCol];
    }

    # If an indel that has an rs ID, add to %rsIndels if rsID is unique
    if ($F[5] eq 'Biallelic_INDEL' || ($F[5] eq 'Multiallelic_INDEL' && (length($F[$legendA1Col]) > 1 || length($F[$legendA2Col]) > 1))) {
        if ($F[$legendIdCol] =~ /^(rs\d+)/) {
            my $rsId = $1;
            if (exists($rsIndels{$rsId})) {
                # delete from hash because not unique
                delete $rsIndels{$rsId};
            } else {
                $rsIndels{$rsId} = $F[$legendIdCol];
            }
        }
    }

}
close LEGEND;


# Process input file
print "Processing input file...\n";
open(FILE_OUT, ">".$fileOut) or die "Cannot open ".$fileOut."\n";
if ($fileIn =~ /\.gz$/) {
    open(FILE_IN, "gunzip -c $fileIn |") or die "Cannot open ".$fileIn."\n";
} else {
    open(FILE_IN, $fileIn) or die "Cannot open ".$fileIn."\n";
}
# Print header
for (my $i=0; $i<$fileInHeader; $i++) {
    my $header = <FILE_IN>;
    $header =~ s/ /\t/g;
    print FILE_OUT $header;
}
while (<FILE_IN>) {

    chomp;
    my @F = split;
    my $chr = exists($xChr{$F[$fileInChrCol]}) ? "X" : $F[$fileInChrCol];
    my $pos = $F[$fileInPosCol];
    my @alleles = (
        $F[$fileInA1Col],
        $F[$fileInA2Col]
    );
    
    # Standardize alleles
    foreach my $allele (@alleles) {
        $allele = uc($allele);
        foreach my $pattern (keys(%indelRegExPatterns)) {
            $allele =~ s/$pattern/-/;
        }
    }
    if (exists($ridAlleles{$alleles[0]}) && exists($ridAlleles{$alleles[1]}) && $F[$fileInIdCol] =~ /^\S+[_:]\d+[_:](\S*)[_:](\S*)$/) {
        $alleles[0] = ($1 ne '') ? $1 : '-';
        $alleles[1] = ($2 ne '') ? $2 : '-';
    }

    # Get allele complements
    my @alleleComplements = ();
    for (my $i=0; $i<2; $i++) {
        $alleleComplements[$i] = flip($alleles[$i], $fileInMonomorphicAllele);
    }

    my @possibleKeys = (
        join("_", $chr, $pos, $alleles[0], $alleles[1]),
        join("_", $chr, $pos, $alleles[1], $alleles[0]),
        join("_", $chr, $pos, $alleleComplements[0], $alleleComplements[1]),
        join("_", $chr, $pos, $alleleComplements[1], $alleleComplements[0])
    );

    my $createId = 1;
    my $monomorphic = ($alleles[0] eq $fileInMonomorphicAllele || $alleles[1] eq $fileInMonomorphicAllele);
    my $rid = (exists($ridAlleles{$alleles[0]}) && exists($ridAlleles{$alleles[1]}));
    if ($rid) {
        if ($F[$fileInIdCol] =~ /^(rs\d+)/ && exists($rsIndels{$1})) {
            $F[$fileInIdCol] = $rsIndels{$1};
            $createId = 0;
        }
    } elsif (!$monomorphic || ($monomorphic && exists($positionVariantCount{$pos}) && $positionVariantCount{$pos} == 1)) {
        foreach my $possibleKey (@possibleKeys) {
            if (exists($variants{$possibleKey})) {
                $F[$fileInIdCol] = $variants{$possibleKey};
                $createId = 0;
            }
        }
    }

    if ($createId) {

        if (!($alleles[0] eq 'A' || $alleles[0] eq 'C' || $alleles[1] eq 'A' || $alleles[1] eq 'C')) {
            $alleles[0] = flip($alleles[0], $fileInMonomorphicAllele);
            $alleles[1] = flip($alleles[1], $fileInMonomorphicAllele);
        }

        if ($alleles[0] eq $fileInMonomorphicAllele) {
            $F[$fileInIdCol] = $chr.":".$pos.":".uc($alleles[1]).":".uc($alleles[0]);
        } elsif ($alleles[1] eq $fileInMonomorphicAllele) {
            $F[$fileInIdCol] = $chr.":".$pos.":".uc($alleles[0]).":".uc($alleles[1]);
        } elsif ($alleles[0] lt $alleles[1]) {
            $F[$fileInIdCol] = $chr.":".$pos.":".uc($alleles[0]).":".uc($alleles[1]);
        } else {
            $F[$fileInIdCol] = $chr.":".$pos.":".uc($alleles[1]).":".uc($alleles[0]);
        }

    }

    print FILE_OUT join("\t", @F)."\n";

}
close FILE_IN;
close FILE_OUT;

print "Done\n";
