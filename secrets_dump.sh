#!/bin/bash
# Quick script to retrieve secrets of all namespaces
#############

TOOL=kubectl

PROJECTS=$($TOOL get projects -o name | cut -d '/' -f2)
for PROJECT in $PROJECTS;
do
	echo "[*] Dumping secrets for project $PROJECT"
	mkdir $PROJECT
	SECRETS=$($TOOL get secrets -o name -n $PROJECT | cut -d '/' -f2)
	for SECRET in $SECRETS;
	do
		echo "$PROJECT:$SECRET"
		$TOOL get secrets $SECRET -n $PROJECT -o json > $PROJECT/$SECRET.json;
	done
done
