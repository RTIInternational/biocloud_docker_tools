#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my %arguments = (
    'metal_command_file' => 'metal_command.txt',
    'scheme' => '',
    'column_counting' => 'STRICT',
    'average_freq' => 'OFF',
    'min_max_freq' => 'OFF',
    'genomic_control' => 'OFF',
    'out_prefix' => 'metal',
    'out_suffix' => '.tsv',
    'separators' => 'WHITESPACE',
    'sum_stats_files' => '',
    'marker_col_names' => 'VARIANT_ID',
    'alt_allele_col_names' => 'ALT',
    'ref_allele_col_names' => 'REF',
    'effect_col_names' => 'ALT_EFFECT',
    'weight_col_names' => '',
    'pvalue_col_names' => '',
    'std_err_col_names' => '',
    'int_effect_col_names' => '',
    'int_std_err_col_names' => '',
    'int_cov_col_names' => '',
    'freq_col_names' => '',
    'analyze' => ''
);

my @arrayArguments = (
    'marker_col_names',
    'alt_allele_col_names',
    'ref_allele_col_names',
    'effect_col_names',
    'separators',
    'weight_col_names',
    'pvalue_col_names',
    'std_err_col_names',
    'int_effect_col_names',
    'int_std_err_col_names',
    'int_cov_col_names',
    'freq_col_names'
);

my %commandArgumentXref = (
    'SCHEME' => 'scheme',
    'COLUMNCOUNTING' => 'column_counting',
    'AVERAGEFREQ' => 'average_freq',
    'MINMAXFREQ' => 'min_max_freq',
    'GENOMICCONTROL' => 'genomic_control',
    'OUTFILE' => 'out_prefix out_suffix',
    'SEPARATOR' => 'separators',
    'MARKERLABEL' => 'marker_col_names',
    'ALLELELABELS' => 'ref_allele_col_names alt_allele_col_names',
    'EFFECTLABEL' => 'effect_col_names',
    'WEIGHTLABEL' => 'weight_col_names',
    'PVALUELABEL' => 'pvalue_col_names',
    'STDERRLABEL' => 'std_err_col_names',
    'INTEFFECTLABEL' => 'int_effect_col_names',
    'INTSTDERRLABEL' => 'int_std_err_col_names',
    'INTCOVLABEL' => 'int_cov_col_names',
    'FREQLABEL' => 'freq_col_names',
    'PROCESSFILE' => 'sum_stats_files',
    'ANALYZE' => 'analyze'
);

my @commandOrder = (
    'SCHEME',
    'COLUMNCOUNTING',
    'AVERAGEFREQ',
    'MINMAXFREQ',
    'GENOMICCONTROL',
    'OUTFILE',
    '[PROCESS]',
    'ANALYZE'
);

my @fileCommandOrder = (
    'SEPARATOR',
    'MARKERLABEL',
    'ALLELELABELS',
    'EFFECTLABEL',
    'WEIGHTLABEL',
    'PVALUELABEL',
    'STDERRLABEL',
    'INTEFFECTLABEL',
    'INTSTDERRLABEL',
    'INTCOVLABEL',
    'FREQLABEL',
    'PROCESSFILE'
);

GetOptions (
    \%arguments,
    'metal_command_file:s',
    'sum_stats_files=s',
    'out_prefix=s',
    'out_suffix:s',
    'scheme=s',
    'column_counting:s',
    'average_freq:s',
    'min_max_freq:s',
    'genomic_control:s',
    'separators:s',
    'marker_col_names:s',
    'alt_allele_col_names:s',
    'ref_allele_col_names:s',
    'effect_col_names:s',
    'weight_col_names:s',
    'pvalue_col_names:s',
    'std_err_col_names:s',
    'int_effect_col_names:s',
    'int_std_err_col_names:s',
    'int_cov_col_names:s',
    'freq_col_names:s',
    'analyze:s'
);

my @requiredArguments = (
    'scheme',
    'sum_stats_files',
    'out_prefix'
);
if ($arguments{'scheme'} eq 'SAMPLESIZE') {
    push(@requiredArguments, 'weight_col_names');
    push(@requiredArguments, 'pvalue_col_names');
} elsif ($arguments{'scheme'} eq 'STDERR') {
    push(@requiredArguments, 'std_err_col_names');
} elsif ($arguments{'scheme'} eq 'INTERACTION') {
    push(@requiredArguments, 'std_err_col_names');
    push(@requiredArguments, 'int_effect_col_names');
    push(@requiredArguments, 'int_std_err_col_names');
    push(@requiredArguments, 'int_cov_col_names');
}
if ($arguments{'average_freq'} eq 'ON' || $arguments{'min_max_freq'} eq 'ON') {
    push(@requiredArguments, 'freq_col_names');
}
foreach my $requiredArgument (@requiredArguments) {
    if ($arguments{$requiredArgument} eq '') { die "Missing required argument " . $requiredArgument; }
}

$arguments{'sum_stats_files'} = [split(',', $arguments{'sum_stats_files'})];
my $sumStatsCount = @{$arguments{'sum_stats_files'}};

foreach my $arrayArgument (@arrayArguments) {
    if ($arguments{$arrayArgument} eq '') {
        $arguments{$arrayArgument} = [];
    } else {
        $arguments{$arrayArgument} = [split(',', $arguments{$arrayArgument})];
        my $argumentCount = @{$arguments{$arrayArgument}};
        if ($argumentCount != $sumStatsCount) {
            if ($argumentCount > 1) {
                die "Invalid value provided for $arrayArgument parameter\n";
            } else {
                $arguments{$arrayArgument} = [($arguments{$arrayArgument}[0])x$sumStatsCount];
            }
        }
    }
}

my $metalCommand = '';

foreach my $command (@commandOrder) {
    if ($command eq '[PROCESS]') {
        for (my $i=0; $i<$sumStatsCount; $i++) {
            foreach my $fileCommand (@fileCommandOrder) {
                my $argument = $commandArgumentXref{$fileCommand};
                my @substitutions = ( $argument =~ /\S+/g );
                foreach my $substitution (@substitutions) {
                    my $argumentCount = @{$arguments{$substitution}};
                    if ($argumentCount > $i) {
                        $argument =~ s/$substitution/$arguments{$substitution}[$i]/;
                    }
                }
                if ($argument ne $commandArgumentXref{$fileCommand}) {
                    $metalCommand .= $fileCommand . ' ' . $argument . "\n";
                }
            }
        }
    } else {
        my $argument = $commandArgumentXref{$command};
        my $addCommand = TRUE;
        my @substitutions = ( $argument =~ /\S+/g );
        foreach my $substitution (@substitutions) {
            if ($arguments{$substitution} eq '' && $substitution ne 'analyze') {
                $addCommand = FALSE;
            } else {
                $argument =~ s/$substitution/$arguments{$substitution}/;
            }
        }
        if ($argument ne $commandArgumentXref{$command} && $addCommand) {
            $metalCommand .= $command . ' ' . $argument . "\n";
        }
    }
}

$metalCommand .= "QUIT\n";

open(OUT, '>' . $arguments{'metal_command_file'});
print OUT $metalCommand;
close OUT;
