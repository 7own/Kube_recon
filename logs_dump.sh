#!/bin/bash
# Simple script to retrieve logs of Kubernetes' containers
# and search for sensitives words inside it to get secrets
#############
RED='\033[0;31m'
OFF='\033[0m'
#############

TOOL="oc"
# Word to search in logs
CATCH="sha256~ eyjh password Basic ldap admin: admin@ root: root@ secret: clientid client_id DC= client_secret tenant_id api_key"

PROJECTS=$($TOOL get project -o name | cut -d '/' -f2)

mkdir logs

SENSITIVE_DATA=""
for PROJECT in $PROJECTS
do
	
		PODS=$($TOOL get pods -n $PROJECT -o name | cut -d '/' -f2)
		mkdir logs/$PROJECT
		for POD in $PODS
		do
		
			echo "[+] Dumping logs --> $PROJECT : $POD"
			CONTAINERS=$($TOOL get pods $POD -o jsonpath='{.spec.containers[*].name}' -n $PROJECT)
			for C in $CONTAINERS
			do
			
				LOG_FILE="logs/$PROJECT/$POD---$C.log"
				echo "          [CONTAINER] $C"
				LOG=$($TOOL logs $POD -c $C -n $PROJECT > $LOG_FILE)

				for WORD in $CATCH
				do
				
					CATCHED=$(cat $LOG_FILE | grep -i $WORD)
					if [[ $CATCHED != "" ]]
					then
						SENSITIVE_DATA+="$LOG_FILE:$WORD\n"
						echo -e "$RED[!] '$WORD' has been found in $LOG_FILE$OFF"
					fi
				
				done
			
			done
		
		done
	
done
echo $SENSITIVE_DATA > logs/sensitive_data.txt
