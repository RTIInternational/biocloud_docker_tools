#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;
use Data::Dumper;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $vcf = '';
my $hladq_variants_file = '';
my $non_hladq_variants_file = '';
my $out_prefix;

GetOptions (
    'vcf=s' => \$vcf,
    'hladq_variants_file=s' => \$hladq_variants_file,
    'non_hladq_variants_file=s' => \$non_hladq_variants_file,
    'out_prefix=s' => \$out_prefix,
) or die("Invalid options");

## Read HLA-DQ variants
my %hladq_variants = ();
open(HLA, $hladq_variants_file);
while (<HLA>) {
    chomp;
    $hladq_variants{$_} = 1;  # Store HLA-DQ variants in a hash for quick lookup
}
close HLA;

## Read non-HLA-DQ variants
my %non_hladq_variants = ();
open(NON_HLA, $non_hladq_variants_file);
while (<NON_HLA>) {
    chomp;
    $non_hladq_variants{$_} = 1;  # Store non-HLA-DQ variants in a hash for quick lookup
}
close NON_HLA;

## Read VCF file
my @samples = ();
my %sample_variant_counts = ();  # Hash to store counts of variants for each sample
open(VCF, $vcf) or die("Cannot open VCF file: $vcf");
while (<VCF>) {
    next if /^##/;  # Skip header lines
    chomp;
    if (/^#CHROM/) {
        my @header = split(/\t/, $_);
        @samples = @header[9..$#header];  # Extract sample IDs
        %sample_variant_counts = map { $_ => { 'hladq' => 0, 'non_hladq' => 0} } @samples;  # Initialize counts for each sample
    } else {
        my @fields = split(/\t/, $_);
        my $variant_id = $fields[2];
        my $variant_type = (exists($hladq_variants{$variant_id}) ? 'hladq' : (exists($non_hladq_variants{$variant_id}) ? 'non_hladq' : 'na'));
        if ($variant_type ne 'na') {
            my @genotypes = @fields[9..$#fields];  # Extract genotypes for all samples
            for my $i (0 .. $#samples) {
                if ($genotypes[$i] ne './.') {  # Non-missing genotype
                    $sample_variant_counts{$samples[$i]}->{$variant_type}++;
                }
            }
        }
    }
}

# Write missingness summary
print $out_prefix."\n";
open(OUT_MISSING_SUMMARY, "> ".$out_prefix."_missing_summary.tsv");
print OUT_MISSING_SUMMARY join("\t", "SAMPLE_ID", "MISSING_HLADQ_COUNT", "MISSING_NON_HLADQ_COUNT")."\n";
for my $sample_id (@samples) {
    my $missing_hladq_count = (scalar keys %hladq_variants) - $sample_variant_counts{$sample_id}->{'hladq'};
    my $missing_non_hladq_count = (scalar keys %non_hladq_variants) - $sample_variant_counts{$sample_id}->{'non_hladq'};
    print OUT_MISSING_SUMMARY join(
        "\t",
        $sample_id,
        scalar(keys(%hladq_variants)) - $sample_variant_counts{$sample_id}{'hladq'},
        scalar(keys(%non_hladq_variants)) - $sample_variant_counts{$sample_id}{'non_hladq'}
    )."\n";
}
close OUT_MISSING_SUMMARY;
