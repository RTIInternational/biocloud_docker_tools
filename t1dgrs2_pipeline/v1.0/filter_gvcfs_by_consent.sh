#!/bin/bash

imported_gvcfs_dir=""
working_dir=""
consent_gvcfs_dir=""
nonconsent_gvcfs_dir=""
master_manifest=""
new_manifest=""

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
									consent_gvcfs_dir=$1
									;;
		--nonconsented_gvcfs_dir )	shift
									nonconsent_gvcfs_dir=$1
									;;
		--master_manifest )			shift
									master_manifest=$1
									;;
		--new_manifest )			shift
									new_manifest=$1
									;;
	esac
	shift
done

imported_gvcfs_dir=$(echo imported_gvcfs_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')
working_dir=$(echo working_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')
consented_gvcfs_dir=$(echo consented_gvcfs_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')
nonconsented_gvcfs_dir=$(echo nonconsented_gvcfs_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')

#change to working dir
cd $working_dir

# This script is designed to take the file from the lab team (Brooke) that has RTI Accession number and T1D consent information and filter those individuals without from the overall list of gz files that come in from GeneDx. In order to do this I must extract all of the T1D consented individuals from the lab manifest list, match the RTI accession numbers from RTIs manifest to the RTI accession number from the GeneDx manifest, and then create a "Keep file" list of GeneDx accession numbers (because all of the gz files are labeled based on GeneDx's accession number), lastly, remove all files that are not in the "keep file" list...simple enough...
####################################
echo "#################################################"
echo "Starting consent filtering script"

#Create list of imported gvcf
imported_gvcfs=temp_GeneDx_accession-imported-gvcfs.txt
ls *gz | cut -d "." -f 1 > $imported_gvcfs

#count how many files are in there. This is needed later. 
GZcount=$(wc -l $imported_gvcfs| cut -d ' ' -f1 )
echo "$GZcount gvcf file are present in imported-gvcfs folder in Merge"

###################################
#Import the RTI manifest. 
#It is written this way so that later we can make it easier to call specific manifests without having to move or erase previous files. We should be able to go into node-RED and type in the ID of the manifest we want to run and it pulls the correct one.

# Making sure the manifest list file exists and isn't empty
if [[ -s $new_manifest ]]; then
    echo "----------------------------"
    echo "Detected a RTI manifest list"
    echo "Will now append working RTI master manifest list"
    
    #This removes the first line in the CSV file (the header), so it is merged properly with the existing complete RTI manifest list. 
    cat $master_manifest $new_manifest > temp2_manifest_file.csv
    echo "Completed appending $new_manifest to $master_manifest"
    
    #This sorts and removes any duplicated data based on the accession numbers in column 2 of the csv. This helped with testing and prevents accidental duplicates when adding data.
    mv $master_manifest $master_manifest.bak
    sort -t ',' -u -k2,2 "temp2_manifest_file.csv" | awk -F, '{print $0}' > $master_manifest
    echo "Completed sorting and filtering for duplicates in the RTI master list" 
else
    echo "--------------------------------------------------------------------"
    echo "No new RTI manifest file detected, continuing with filtering for T1D consents"
fi

echo " Successfully passed new RTI manifest append loop"

#Quantify the number of total consents currently in the master file. All of the RTI consented individuals. 
RTI_total_ind=$(wc -l $master_manifest | cut -d ' ' -f1 )

#filter for T1D consent
grep 'T1D' $master_manifest| cut -d "," -f 2 > temp_RTI_accessions_consented_T1D.txt
grep -v 'AccessionNumber' temp_RTI_accessions_consented_T1D.txt > temp2_RTI_accessions_consented_T1D.txt

#Quantify the number of consented individuals
#wc -l RTI_accessions_consented_T1D.txt 
RTIconsents=$(wc -l "temp2_RTI_accessions_consented_T1D.txt" | cut -d ' ' -f1 )
echo "$RTIconsents consented individuals out of $RTI_total_ind."

################################
#GeneDx manifest
#Because all of the GeneDx manifest will have the name and come in the Excel file, we have to convert it to a csv using the [xlsx2csv] command
#pip install xlsx2csv #if you are running this on a new machine

cp ${imported_gvcfs_dir}RTI_Copy_Results_File.xlsx $working_dir/RTI_Copy_Results_File_current.xlsx
GeneDx_manifest=GeneDx_manifest.csv
xlsx2csv ${imported_gvcfs_dir}RTI_Copy_Results_File.xlsx $GeneDx_manifest

#Quantify the number of individual samples in this file.
GeneDx_total_ind=$(wc -l $GeneDx_manifest | cut -d ' ' -f1 )

#################################
#Match IDs from the RTI accession consents to the GeneDx manifest
grep -F -f temp2_RTI_accessions_consented_T1D.txt $GeneDx_manifest | cut -d "," -f 1 > temp_Matched_GeneDx_accessions.txt

#Quantify the number of matches 
Match1=$(wc -l "temp_Matched_GeneDx_accessions.txt" | cut -d ' ' -f1 )
echo "$Match1 matches from consented individuals were observed from the $GeneDx_total_ind in the manifest list received from GeneDx."
################################
#Matching part 2. Matching the matched consented GeneDx accessions with the overall imported gvcf list.
grep -F -f temp_Matched_GeneDx_accessions.txt temp_GeneDx_accession-imported-gvcfs.txt > temp_Matched_imported_consent_accessions.txt

#Quantify the number of matches part 2 
Match2=$(wc -l "temp_Matched_imported_consent_accessions.txt" | cut -d ' ' -f1 )
echo "$Match2 observed matches between consented GeneDx accession numbers and imported GeneDx samples."

################################
#Renaming and moving the files
sed -i 's/$/.hard-filtered.gvcf.gz/' temp_Matched_imported_consent_accessions.txt

while IFS= read -r accession; do
    mv "$accession" $consented_gvcfs_dir
    echo "Moved $accession to $consented_gvcfs_dir"
done < temp_Matched_imported_consent_accessions.txt

echo "Successfully moved all consented files to gvcfs folder"

###############################
#Move remaining gz files that don't have consent to the alternate folder
remaining_files=$(ls *.gz |wc -l | cut -d ' ' -f1)

echo "Moving the remaining $remaining_files gvcf files. Along with the tbi files. Will remove them later"

mv *.gz* $nonconsented_gvcfs_dir
echo "Successfully moved nonconsented gvcfs to nonconsent-gvcfs folder"

################################
#Archiving the GeneDx manifest.

# #This is needed for the PRS merge script at the end of the pipeline
# cp $GeneDx_manifest "/home/merge-shared-folder/imported-gvcfs/filtering/Gene_manifest_current.csv"
# # Get the current Julian date
# julian_date=$(date '+%j')

# # Create the new file name with the Julian date
# new_file_name="GeneDx_manifest_${julian_date}.csv"

# # Rename the file
# mv "$GeneDx_manifest" "/home/merge-shared-folder/imported-gvcfs/filtering/$new_file_name"

# echo "File renamed to: $new_file_name"

#################################
#remove temp files and original GeneDx manifest list
# rm temp*
# rm RTI_Copy_Results_File.xlsx
#################################################################
echo "Filtering via consent is complete: $(date):" 
echo "T1D filtering script is now complete "
echo "##########################################"
