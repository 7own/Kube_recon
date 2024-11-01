#!/bin/bash
# Simple script to find secrets inside cluster resources
#############
RED='\033[0;31m'
COFF='\033[0m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
#############
TOOL=oc

PROJECTS=$($TOOL get projects -o name | cut -d '/' -f2)
SECRETS="eyjh clientId clientSecret apikey" # secrets
FOLDER="$PWD/0_FINDINGS"
OUTFILE="$FOLDER/oc_secrets_found.txt"

if [ ! -d "$FOLDER" ]; then
	mkdir $FOLDER
fi
if [ -f "$OUTFILE" ]; then
	OVERWRITE=$(read -p "$OUTFILE already exist. Do you want to override ? (y/N)")
	if [[ "y" = *"$OVERWRITE"* || "Y" = *"$OVERWRITE"* ]]; then
		rm -rf $OUTFILE
		echo "[*] Overwriting last results : $OUTFILE"
	else
		OUTFILE="$FOLDER/oc_secrets_found-$(date +'%m%d%Y-%H_%M_%N').txt"
		echo "[*] Creating new file for the results : $OUTFILE"
	fi
fi

for PROJECT in $PROJECTS
do
	echo -e "$CYAN[*] Searching sensitives keywords in$COFF$ORANGE $PROJECT$COFF$CYAN's resources$COFF"
	RESULT=$($TOOL get all -o yaml -n $PROJECT)
	for SECRET in $SECRETS
	do
		
		echo "[*] Searching for $SECRET..."
		CATCHED=$(echo "$RESULT" | grep -i $SECRET)
		CATCHED_LENGHT=$(echo "$CATCHED" | wc -w)
		if [[ "$CATCHED_LENGHT" -gt "0" ]]
		then
			if [[ "$CATCHED_LENGHT" -gt "50" ]]
			then
				echo -e "$ORANGE[!]$COFF Found $ORANGE'$SECRET'$COFF inside a resource but it may be a false positive. Lenght: $CATCHED_LENGHT"
				echo -e "[########## $PROJECT ##########]\n$CATCHED\n[##############################]" >> $OUTFILE
			else
				echo -e "$RED[+]$COFF Found $RED$SECRET$COFF inside $PROJECT:$SECRET"
				echo -e "[########## $PROJECT ##########]\n$CATCHED\n[##############################]" >> $OUTFILE
			fi
		fi
		
	
	done
	echo ""
done

echo "[*] Output file : $OUTFILE"
