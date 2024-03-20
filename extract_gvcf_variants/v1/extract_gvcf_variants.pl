#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use JSON;
use constant FALSE => 0;
use constant TRUE  => 1;
use Data::Dumper;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $fileInArgs = '';

GetOptions (
    'args=s' => \$fileInArgs,
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

# Read arguments
my $args_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $fileInArgs)
      or die("Can't open \"$fileInArgs\": $!\n");
   local $/;
   <$json_fh>
};
my $json = JSON->new;
my $args = $json->decode($args_text);

my %refAlleles = ();
my %altAlleles = ();
my @F = ();

# Read extract file
if ($args->{file_in_extract} =~ /gz$/) {
    open(EXTRACT, "gunzip -c $args->{file_in_extract} |") or die "gunzip $args->{file_in_extract}: $!";
} else {
    open(EXTRACT, $args->{file_in_extract});
}
while (<EXTRACT>) {
    chomp;
    @F = split();
    $refAlleles{$F[0]} = $F[1];
    $altAlleles{$F[0]} = $F[2];
}
close EXTRACT;

# Get dataset variants by position
open(OUT_VCF, "> ".$args->{file_out_prefix}.".vcf");
if ($args->{file_in_gvcf} =~ /gz$/) {
    open(GVCF, "gunzip -c $args->{file_in_gvcf} |") or die "gunzip $args->{file_in_gvcf}: $!";
} else {
    open(GVCF, $args->{file_in_gvcf});
}
print "Extracting variants...\n";
while(<GVCF>){
    if (/^#/) {
        print OUT_VCF;
    } else {
        chomp;
        @F =split("\t");
        if (
            !$args->{pass_only}
            || (uc($F[6]) eq "PASS")
        ) {
            if ($F[0] =~ /chr(\d+)$/) {
                my $chr = $1;
                my @keys = split(":", $F[8]);
                my @values = split(":", $F[9]);
                my %variantData;
                @variantData{@keys} = @values;
                $variantData{"GT"} =~ /(\d+|\.).(\d+|\.)/;
                my $sampleA1Index = $1;
                my $sampleA2Index = $2;
                $F[9] =~ s/^(\d+|\.).(\d+|\.)/$sampleA1Index|$sampleA2Index/;
                if (
                    !$args->{filter_by_gq}
                    || (
                        (
                            $sampleA1Index eq $sampleA2Index
                            && $variantData{"GQ"} >= $args->{hom_gq_threshold}
                        )
                        || (
                            $sampleA1Index ne $sampleA2Index
                            && ($variantData{"GQ"} >= $args->{het_gq_threshold})
                        )
                    )
                ) {
                    if ($F[7] =~ /END=(\d+)/) {
                        my $end = $1;
                        for (my $i=$F[1]; $i<=$end; $i++) {
                            my $chrPos = $chr.":".$i;
                            if (exists($refAlleles{$chrPos})) {
                                my $id = join(":", $chrPos, $refAlleles{$chrPos}, $altAlleles{$chrPos});
                                print OUT_VCF join("\t", $chr, $i, $id, $refAlleles{$chrPos}, $altAlleles{$chrPos}, @F[5..6], ".", $F[8], $F[9])."\n";
                                delete($refAlleles{$chrPos});
                            }
                        }
                    } else {
                        my $chrPos = $chr.":".$F[1];
                        if (exists($refAlleles{$chrPos}) && $F[3] eq $refAlleles{$chrPos}) {
                            my %sampleAlleles = ();
                            $sampleAlleles{'0'} = 1;
                            $sampleAlleles{$sampleA1Index} = 1;
                            $sampleAlleles{$sampleA2Index} = 1;
                            if (keys(%sampleAlleles) < 3) {
                                my @alleles =($F[3]);
                                push(@alleles, split(",", $F[4]));
                                if (@alleles == 3) {
                                    $F[4] = $alleles[1];
                                } else {
                                    if ($sampleA2Index != 0) {
                                        $F[4] = $alleles[$sampleA2Index];
                                    } elsif ($sampleA1Index != 0) {
                                        $F[4] = $alleles[$sampleA1Index];
                                    }
                                }
                                if ($F[4] eq $altAlleles{$chrPos}) {
                                    my $id = join(":", $chrPos, $F[3], $F[4]);
                                    print OUT_VCF join("\t", $chr, $F[1], $id, @F[3..9])."\n";
                                    delete($refAlleles{$chrPos});
                                }
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

# Write list of missing positions
my @missing = sort(keys(%refAlleles));
open(OUT_MISSING, "> ".$args->{file_out_prefix}.".missing");
foreach my $position (@missing) {
    print OUT_MISSING $position."\n";
}
close OUT_MISSING;

# Convert to plink bfile format
print "Converting to plink bfile format\n";
my @commandArgs = (
    "plink2",
    "--vcf",
    $args->{file_out_prefix}.".vcf",
    "--make-bed",
    "--out",
    $args->{file_out_prefix}
);
system(@commandArgs) == 0
    or die "Plink conversion failed\n";
