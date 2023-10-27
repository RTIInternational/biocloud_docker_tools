#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $fileInRawAncestryAssignment = '';
my $stdDevCutoff = 3;
my $fileOutAncestryAssignment = '';

GetOptions (
    'file_in_raw_ancestry_assignment=s' => \$fileInRawAncestryAssignment,
    'std_dev_cutoff:i' => \$stdDevCutoff,
    'file_out_ancestry_assignment=s' => \$fileOutAncestryAssignment
) or die("Invalid options");

open(RAW_ANCESTRY, $fileInRawAncestryAssignment);
my $header = <RAW_ANCESTRY>;
my $assignmentRow = <RAW_ANCESTRY>;
$assignmentRow =~ /(\S+)\s+(\S+)$/;
my $scaledMahal = $1;
my $assignment = $2;
close RAW_ANCESTRY;

open(ASSIGNMENT, "> ".$fileOutAncestryAssignment);
if (abs($scaledMahal) <= $stdDevCutoff) {
    print ASSIGNMENT $assignment."\n";
} else {
    print ASSIGNMENT "Unassigned\n";
}
close ASSIGNMENT;
