#!/usr/bin/perl

# From: github.com/RTIInternational/bioinformatics/blob/master/software/perl/id_conversion/convert_to_1000g_p3_ids.pl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $fileIn = '';
my $fileOut = '';
my $legend = '';
my $fileInHeader = -1;
my $fileInIdCol = -1;
my $fileInChrCol = -1;
my $fileInPosCol = -1;
my $fileInAllele1Col = -1;
my $fileInAllele2Col = -1;
my $chr = -1;
my $indelNotation = '1000G';

GetOptions ('file_in=s' => \$fileIn,
            'file_out=s' => \$fileOut,
            'legend=s' => \$legend,
            'file_in_header=i' => \$fileInHeader,
            'file_in_id_col=i' => \$fileInIdCol,
            'file_in_chr_col=i' => \$fileInChrCol,
            'file_in_pos_col=i' => \$fileInPosCol,
            'file_in_a1_col=i' => \$fileInAllele1Col,
            'file_in_a2_col=i' => \$fileInAllele2Col,
            'chr=i' => \$chr);

if ($fileIn eq '') { die "Please provide an input file\n"; }
if ($fileOut eq '') { die "Please provide an output file\n"; }
if ($legend eq '') { die "Please provide a legend file\n"; }
if ($fileInIdCol eq -1) { die "Please provide the ID column in the input file\n"; }
if ($fileInChrCol eq -1) { die "Please provide the chromosome column in the input file\n"; }
if ($fileInPosCol eq -1) { die "Please provide the position column in the input file\n"; }
if ($fileInAllele1Col eq -1) { die "Please provide the allele 1 column in the input file\n"; }
if ($fileInAllele2Col eq -1) { die "Please provide the allele 2 column in the input file\n"; }
if ($chr eq -1) { die "Please provide the chromosome\n"; }


my %thousandGenomeVariants = ();
my %thousandGenomeVariantsMonomorphic = ();
my %thousandGenomePositionVariantCount = ();
my %thousandGenomeIndels = ();
my %normalAlleles = (
    'A' => 1,
    'C' => 1,
    'G' => 1,
    'T' => 1,
    '-' => 1
);
my %monomorphicAlleles = (
    'A' => 1,
    'C' => 1,
    'G' => 1,
    'T' => 1,
    '0' => 1
);
my %ridAlleles = (
    'R' => 1,
    'I' => 1,
    'D' => 1
);

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
    $F[2] = uc($F[2]);
    $F[3] = uc($F[3]);
    # Increment count for position of variant by 1 in %thousandGenomePositionVariantCount
    if (exists($thousandGenomePositionVariantCount{$F[1]})) {
        $thousandGenomePositionVariantCount{$F[1]}++;
    } else {
        $thousandGenomePositionVariantCount{$F[1]} = 1;
    }
    # Add variant to %thousandGenomeVariants
    $thousandGenomeVariants{join('_', $chr, $F[1], $F[2], $F[3])} = $F[0];
    # If an indel, also add an entry for the alternative notation that uses "-" for one of the alleles
    if ($F[4] eq 'Biallelic_INDEL' || ($F[4] eq 'Multiallelic_INDEL' && (length($F[2]) == 1 || length($F[3]) == 1))) {
        my $allele1 = $F[2];
        $allele1 =~ s/^.//;
        $allele1 = ($allele1 eq '') ? '-' : $allele1;
        my $allele2 = $F[3];
        $allele2 =~ s/^.//;
        $allele2 = ($allele2 eq '') ? '-' : $allele2;
        $thousandGenomeVariants{join('_', $chr, ($F[1] + 1), $allele1, $allele2)} = $F[0];
    }
    # Add entries to %thousandGenomeVariantsMonomorphic to account for the fact that some variants may be monomorphic in the file to be converted
    $thousandGenomeVariantsMonomorphic{join('_', $chr, $F[1], $F[2], '0')} = $F[0];
    $thousandGenomeVariantsMonomorphic{join('_', $chr, $F[1], $F[3], '0')} = $F[0];
    # If an indel that has an rs ID, get the id, chr, position, and alleles - will enable conversion of indels in R/I/D format that have an rs ID
    if ($F[4] eq 'Biallelic_INDEL' || ($F[4] eq 'Multiallelic_INDEL' && (length($F[2]) > 1 || length($F[3]) > 1))) {
        if ($F[0] =~ /^(rs\d+)/) {
            my $rsId = $1;
            if (exists($thousandGenomeIndels{$rsId})) {
                # delete from hash because not unique
                delete $thousandGenomeIndels{$rsId};
            } else {
                if (length($F[2]) > length($F[3])) {
                    $thousandGenomeIndels{$rsId} = { id => $F[0], chr => $chr, position => $F[1], allele_long => $F[2], allele_short => $F[3] };
                } elsif (length($F[3]) > length($F[2])) {
                    $thousandGenomeIndels{$rsId} = { id => $F[0], chr => $chr, position => $F[1], allele_short => $F[2], allele_long => $F[3] };
                }
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
for (my $i=0; $i<$fileInHeader; $i++) {
    my $header = <FILE_IN>;
    $header =~ s/ /\t/g;
    print FILE_OUT $header;
}
while (<FILE_IN>) {
    chomp;
    my @F = split;
    my $createId = 0;
    $F[$fileInAllele1Col] = uc($F[$fileInAllele1Col]);
    $F[$fileInAllele2Col] = uc($F[$fileInAllele2Col]);
    $F[$fileInAllele1Col] =~ s/<DEL>/-/;
    $F[$fileInAllele2Col] =~ s/<DEL>/-/;
    $F[$fileInAllele1Col] =~ s/^!.*/-/;
    $F[$fileInAllele2Col] =~ s/^!.*/-/;
    $F[$fileInAllele1Col] =~ s/NA/-/;
    $F[$fileInAllele2Col] =~ s/NA/-/;
    if (exists($ridAlleles{$F[$fileInAllele1Col]}) && exists($ridAlleles{$F[$fileInAllele2Col]}) && $F[$fileInIdCol] =~ /^\S+[_:]\d+[_:](\S*)[_:](\S*)$/) {
        $F[$fileInAllele1Col] = ($1 ne '') ? $1 : '-';
        $F[$fileInAllele2Col] = ($2 ne '') ? $2 : '-';
    }

    my $alleleCategory = "other";
    if (length($F[$fileInAllele1Col]) == 1 && length($F[$fileInAllele2Col]) == 1) {
        if (exists($normalAlleles{$F[$fileInAllele1Col]}) && exists($normalAlleles{$F[$fileInAllele2Col]})) {
            $alleleCategory = "normal";
        } elsif (exists($monomorphicAlleles{$F[$fileInAllele1Col]}) && exists($monomorphicAlleles{$F[$fileInAllele2Col]})) {
            $alleleCategory = "monomorphic";
        } elsif (exists($ridAlleles{$F[$fileInAllele1Col]}) && exists($ridAlleles{$F[$fileInAllele2Col]})) {
            $alleleCategory = "rid";
        }
    } else {
        $alleleCategory = "normal";
        my @alleles = split("",$F[$fileInAllele1Col]);
        push(@alleles, split("",$F[$fileInAllele2Col]));
        foreach my $nt (@alleles) {
            if (!exists($normalAlleles{$nt})) {
                $alleleCategory = "monomorphic";
                if (!exists($monomorphicAlleles{$nt})) {
                    $alleleCategory = "other";
                    last;
                }
            }
        }
    }

    my $allele1Complement = "";
    my $allele2Complement = "";
    foreach my $nt (reverse(split("",$F[$fileInAllele1Col]))) {
        my $ntComplement = ($nt eq "A") ? "T" : (($nt eq "C") ? "G" : (($nt eq "G") ? "C" : (($nt eq "T") ? "A" : $nt)));
        $allele1Complement .= $ntComplement;
    }
    foreach my $nt (reverse(split("",$F[$fileInAllele2Col]))) {
        my $ntComplement = ($nt eq "A") ? "T" : (($nt eq "C") ? "G" : (($nt eq "G") ? "C" : (($nt eq "T") ? "A" : $nt)));
        $allele2Complement .= $ntComplement;
    }
    $F[$fileInChrCol] = ($F[$fileInChrCol] eq 'X') ? 23 : $F[$fileInChrCol];

    if ($alleleCategory eq "normal") {
        if (exists($thousandGenomeVariants{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $F[$fileInAllele1Col], $F[$fileInAllele2Col])})) {
            $F[$fileInIdCol] = $thousandGenomeVariants{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $F[$fileInAllele1Col], $F[$fileInAllele2Col])};
        } elsif (exists($thousandGenomeVariants{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $F[$fileInAllele2Col], $F[$fileInAllele1Col])})) {
            $F[$fileInIdCol] = $thousandGenomeVariants{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $F[$fileInAllele2Col], $F[$fileInAllele1Col])};
        } elsif (exists($thousandGenomeVariants{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $allele1Complement, $allele2Complement)})) {
                $F[$fileInIdCol] = $thousandGenomeVariants{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $allele1Complement, $allele2Complement)};
        } elsif (exists($thousandGenomeVariants{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $allele2Complement, $allele1Complement)})) {
            $F[$fileInIdCol] = $thousandGenomeVariants{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $allele2Complement, $allele1Complement)};
        } else {
            $createId = 1;
        }
    } elsif ($alleleCategory eq "monomorphic") {
        if (exists($thousandGenomePositionVariantCount{$F[$fileInPosCol]}) && $thousandGenomePositionVariantCount{$F[$fileInPosCol]} == 1) {
            if (exists($thousandGenomeVariantsMonomorphic{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $F[$fileInAllele1Col], $F[$fileInAllele2Col])})) {
                $F[$fileInIdCol] = $thousandGenomeVariantsMonomorphic{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $F[$fileInAllele1Col], $F[$fileInAllele2Col])};
            } elsif (exists($thousandGenomeVariantsMonomorphic{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $F[$fileInAllele2Col], $F[$fileInAllele1Col])})) {
                $F[$fileInIdCol] = $thousandGenomeVariantsMonomorphic{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $F[$fileInAllele2Col], $F[$fileInAllele1Col])};
            } elsif (exists($thousandGenomeVariantsMonomorphic{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $allele1Complement, $allele2Complement)})) {
                    $F[$fileInIdCol] = $thousandGenomeVariantsMonomorphic{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $allele1Complement, $allele2Complement)};
            } elsif (exists($thousandGenomeVariantsMonomorphic{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $allele2Complement, $allele1Complement)})) {
                $F[$fileInIdCol] = $thousandGenomeVariantsMonomorphic{join("_", $F[$fileInChrCol], $F[$fileInPosCol], $allele2Complement, $allele1Complement)};
            } else {
                $createId = 1;
            }
        } else {
            $createId = 1;
        }
    } elsif ($alleleCategory eq "rid") {
        if ($F[$fileInIdCol] =~ /^(rs\d+)/ && exists($thousandGenomeIndels{$1})) {
            my $rsId = $1;
            $F[$fileInIdCol] = $thousandGenomeIndels{$rsId}{id};
            $F[$fileInChrCol] = $thousandGenomeIndels{$rsId}{chr};
            $F[$fileInPosCol] = $thousandGenomeIndels{$rsId}{position};
            if (($F[$fileInAllele1Col] eq 'R' && $F[$fileInAllele2Col] eq 'I') || ($F[$fileInAllele1Col] eq 'D' && $F[$fileInAllele2Col] eq 'R')) {
                $F[$fileInAllele1Col] = $thousandGenomeIndels{$rsId}{allele_short};
                $F[$fileInAllele2Col] = $thousandGenomeIndels{$rsId}{allele_long};
            } else {
                $F[$fileInAllele1Col] = $thousandGenomeIndels{$rsId}{allele_long};
                $F[$fileInAllele2Col] = $thousandGenomeIndels{$rsId}{allele_short};
            }
        } else {
            $createId = 1;
        }
    } else {
        $createId = 1;
    }
    if ($createId) {
        $chr = ($chr eq '23') ? 'X' : $chr;
        if ($F[$fileInAllele1Col] eq 'G' && ($F[$fileInAllele2Col] eq 'T' || $F[$fileInAllele2Col] eq '0')) {
            $F[$fileInAllele1Col] = 'C';
        } elsif ($F[$fileInAllele1Col] eq 'T' && ($F[$fileInAllele2Col] eq 'G' || $F[$fileInAllele2Col] eq '0')) {
            $F[$fileInAllele1Col] = 'A';
        }
        if ($F[$fileInAllele2Col] eq 'G' && ($F[$fileInAllele1Col] eq 'T' || $F[$fileInAllele1Col] eq '0')) {
            $F[$fileInAllele2Col] = 'C';
        } elsif ($F[$fileInAllele2Col] eq 'T' && ($F[$fileInAllele1Col] eq 'G' || $F[$fileInAllele1Col] eq '0')) {
            $F[$fileInAllele2Col] = 'A';
        }
        if ($F[$fileInAllele1Col] lt $F[$fileInAllele2Col]) {
            $F[$fileInIdCol] = $chr.":".$F[$fileInPosCol].":".uc($F[$fileInAllele1Col]).":".uc($F[$fileInAllele2Col]);
        } else {
            $F[$fileInIdCol] = $chr.":".$F[$fileInPosCol].":".uc($F[$fileInAllele2Col]).":".uc($F[$fileInAllele1Col]);
        }
    }
    print FILE_OUT join("\t", @F)."\n";
}
close FILE_IN;
close FILE_OUT;

print "Done\n";