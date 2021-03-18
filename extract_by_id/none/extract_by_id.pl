#!/usr/bin/perl

# Copied from github.com/RTIInternational/bioinformatics/blob/master/software/perl/utilities/extract_rows.pl

# Example:
# perl /share/nas02/bioinformatics_group/software/perl/extract_rows.pl \
#  --source /share/nas02/bioinformatics_group/data/ref_panels/hapmap_phase_3/beagle/ALL/hapmap3_r2_b36_chr22.5MB_chunk.0.marker \
#  --id_list /share/nas02/bioinformatics_group/data/ref_panels/hapmap_phase_3/beagle/ALL/hapmap3_r2_b36_chr22.5MB_chunk.0.keep_snps \
#  --out /share/nas02/bioinformatics_group/data/ref_panels/hapmap_phase_3/beagle/ALL/hapmap3_r2_b36_chr22.5MB_chunk.0.keep.marker \
#  --header 0 \
#  --id_column 0

use strict;
use warnings;
use Getopt::Long;
use constant FALSE => 0;
use constant TRUE  => 1;

# Autoflush STDOUT
select((select(STDOUT), $|=1)[0]);

my $fileSource = '';
my $fileIdList = '';
my $fileOut = '';
my $remove = FALSE;
my $sourceHeaderRowCount = 0;
my $sourceIdColumn = 0;

GetOptions ('source=s' => \$fileSource,					# Name of file from which rows will be extracted
			'id_list=s' => \$fileIdList,				# Name of file containing list of identifiers for rows to be extracted or removed
			'out=s' => \$fileOut,						# Name of output file
			'remove' => \$remove,				 		# Rows corresponding to items in the ID list will be removed rather than extracted
			'header:i' => \$sourceHeaderRowCount,		# Number of header rows in source file
			'id_column:i' => \$sourceIdColumn);			# Column in source file containing ID (column numbering starts with 0)

if ($sourceIdColumn < 0) {
	die "Invalid --id_column\n";
}

my %idList = ();		# IDs of rows to extract or remove
my $row = 0;			# Current line number in source file
my $inIdList = FALSE;	# Whether the ID for the current row is in the id list

# Read in ID list
print "Reading ID list...\n";
if ($fileIdList =~ /\.gz$/) {
	open(FILE_ID_LIST, "gunzip -c $fileIdList |") or die "Cannot open ".$fileIdList."\n";
} else {
	open(FILE_ID_LIST, $fileIdList) or die "Cannot open ".$fileIdList."\n";
}
while (<FILE_ID_LIST>){
	chomp;
	$idList{$_} = 1;
}
close FILE_ID_LIST;

# Process source file
print "Extracting rows...\n";
open(FILE_OUT, ">".$fileOut) or die "Cannot open ".$fileOut."\n";
if ($fileSource =~ /\.gz$/) {
	open(FILE_SOURCE, "gunzip -c $fileSource |") or die "Cannot open ".$fileSource."\n";
} else {
	open(FILE_SOURCE, $fileSource) or die "Cannot open ".$fileSource."\n";
}
while (<FILE_SOURCE>) {
	chomp;
	if ($row < $sourceHeaderRowCount) {
		print FILE_OUT $_."\n";
		$row++;
	} else {
		my @fields = split;
		if ($sourceIdColumn < @fields) {
			$inIdList = exists $idList{$fields[$sourceIdColumn]};
			if (($inIdList && !$remove) || (!$inIdList && $remove)) {
				print FILE_OUT $_."\n";
			}
		} else {
			die "Invalid --id_column\n";
		}
	}
}
close FILE_SOURCE;
close FILE_OUT;

print "Done\n";