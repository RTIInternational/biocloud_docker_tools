#!/usr/bin/perl

$popFlag=$ARGV[0];
$popToUse=$ARGV[1];

while (<STDIN>) {
	chomp;
	@fields=split /\s+/;
	#Family ID
	$fam=$fields[0];
	#Individual ID
	$id=$fields[1];
	#Paternal ID
	#Maternal ID
	#Sex (1=male; 2=female; other=unknown)
	#Phenotype

	if ($popToUse ne "") {
		$line1=$fam."_".$id." ".$popToUse;
		$line2=$fam."_".$id." ".$popToUse;
	} else {
		$line1=$fam."_".$id." 1";
		$line2=$fam."_".$id." 1";
	}
	if ($popFlag ne "") {
		$line1.=" ".$popFlag;
		$line2.=" ".$popFlag;
	}

	for ($x=6; $x<scalar @fields-1; $x=$x+2) {
		$line1 .= " ".txBase($fields[$x]);
		$line2 .= " ".txBase($fields[$x+1]);
	}
	print $line1."\n";
	print $line2."\n";
}


sub txBase {
	$oldBase=shift @_;
	if ($oldBase eq "A") {
		return 1;
	} elsif ($oldBase eq "T") {
		return 4;
	} elsif ($oldBase eq "G") {
		return 3;
	} elsif ($oldBase eq "C") {
		return 2;
	} elsif ($oldBase eq "0") {
		return -9;
	}
}