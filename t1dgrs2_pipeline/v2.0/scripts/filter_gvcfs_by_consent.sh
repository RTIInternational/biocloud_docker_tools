#!/bin/bash

imported_gvcfs_dir=""
working_dir=""
consented_gvcfs_dir=""
nonconsented_gvcfs_dir=""
master_rti_manifest=""
new_rti_manifest=""
genedx_manifest=""

while [ "$1" != "" ]; 
do
	case $1 in
		--imported_gvcfs_dir )		shift
									imported_gvcfs_dir=$1
									;;
		--working_dir )			    shift
									working_dir=$1
									;;
		--consented_gvcfs_dir )		shift
									consented_gvcfs_dir=$1
									;;
		--nonconsented_gvcfs_dir )	shift
									nonconsented_gvcfs_dir=$1
									;;
		--master_rti_manifest )		shift
									master_rti_manifest=$1
									;;
	esac
	shift
done

imported_gvcfs_dir=$(echo $imported_gvcfs_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')
mkdir -p $imported_gvcfs_dir
working_dir=$(echo $working_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')
mkdir -p $working_dir
consented_gvcfs_dir=$(echo $consented_gvcfs_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')
mkdir -p $consented_gvcfs_dir
nonconsented_gvcfs_dir=$(echo $nonconsented_gvcfs_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')
mkdir -p $nonconsented_gvcfs_dir

# This script is designed to take the file from the lab team (Brooke) that has RTI Accession number and T1D consent information and filter those individuals without from the overall list of gz files that come in from GeneDx. In order to do this I must extract all of the T1D consented individuals from the lab manifest list, match the RTI accession numbers from RTIs manifest to the RTI accession number from the GeneDx manifest, and then create a "Keep file" list of GeneDx accession numbers (because all of the gz files are labeled based on GeneDx's accession number), lastly, remove all files that are not in the "keep file" list...simple enough...
####################################
echo "#################################################"
echo "Starting consent filtering script"

#Quantify the number of total consents currently in the master file. All of the RTI consented individuals. 
rti_manifest_sample_count=$(wc -l $master_rti_manifest | cut -d ' ' -f1 )
echo "$rti_manifest_sample_count total samples in RTI manifest"
rti_manifest_t1d_consent_count=$(grep T1D $master_rti_manifest | wc -l)
echo "$rti_manifest_t1d_consent_count consented samples in RTI manifest"

#Create list of imported gvcf
imported_gvcfs=${working_dir}temp_GeneDx_accession-imported-gvcfs.txt
ls $imported_gvcfs_dir*gvcf.gz > $imported_gvcfs
gvcf_count=$(wc -l $imported_gvcfs| cut -d ' ' -f1)
echo "$gvcf_count imported gvcf files"

perl -lne '
    use warnings;
	BEGIN {
		%t1dgrs2_consent = ();
		open(RTI_MANIFEST, "'$master_rti_manifest'");
		while(<RTI_MANIFEST>) {
			@F = split(",");
			if ($F[5] =~ //) {
				$t1dgrs2_consent{$F[1]} = 1;
			}
		}
		close RTI_MANIFEST;
		@consented = ();
		@nonconsented = ();
	}
	chomp;
	/(\d+).hard-filtered/;
	$genedx_accession = $1;
	if (exists($t1dgrs2_consent{$accession_xref{$genedx_accession}})) {
		push(@consented, $genedx_accession);
		print "mv $_ '$consented_gvcfs_dir'";
	} else {
		push(@nonconsented, $genedx_accession);
		print "mv $_ '$nonconsented_gvcfs_dir'";
	}
	END {
		open(CONSENTED, ">'$working_dir'consented.txt");
		print CONSENTED join("\t", "GENEDX_ACCESSION", "RTI_ACCESSION");
		foreach $genedx_accession (sort(@consented)) {
			print CONSENTED join("\t", $genedx_accession, $accession_xref{$genedx_accession});
		}
		close CONSENTED;
		open(NONCONSENTED, ">'$working_dir'nonconsented.txt");
		print NONCONSENTED join("\t", "GENEDX_ACCESSION", "RTI_ACCESSION");
		foreach $genedx_accession (sort(@nonconsented)) {
			print NONCONSENTED join("\t", $genedx_accession, $accession_xref{$genedx_accession});
		}
		close NONCONSENTED;
	}
' $imported_gvcfs | /bin/sh

consented_count=$(tail -n +2 ${working_dir}consented.txt | wc -l)
echo "$consented_count consented gvcf files"

nonconsented_count=$(tail -n +2 ${working_dir}nonconsented.txt | wc -l)
echo "$nonconsented_count nonconsented gvcf files"

echo "Successfully filtered gvcfs by consent"
