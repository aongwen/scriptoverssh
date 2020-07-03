#!/bin/bash
#==========================================================
#Author : Sridhara Shastry (Bring Global)				  #
#Revised by: Alex Mulima Ong'wen (Bring Global)	  		  #
#Reviewed by: Sridhara Shastry (Bring Global)			  #
#==========================================================
# Deployment automation script
#==========================================================


# Functions to read properties file
getProperty(){
         
        prop_value=`cat ${PROP_FILE_NAME} | grep $1 | cut -d'=' -f2`
		echo $prop_value
}
# Functions to print output to screen 
printout(){

	dt=$(date '+%d/%m/%Y %H:%M:%S');
	
	activityName="${YELLOW}$2${NC}"
	echo -e "[$dt] : $activityName $1"

}
# Functions to change case of the input
changeCase(){

	inputData=$1
	changeFlag=$2
    
    case $changeFlag in
		0) 
			inputData=${inputData,,}
			echo $inputData
			;;
		1) 
			inputData=${inputData^^}
			echo $inputData
			;;
		*) 
			echo $inputData ;;
    esac  
}

getirstid(){
 irstid=$(($irstid + 1))
 echo $irstid
}
# Functions to check the current note status of the integration node (broker)
getNodeCurrentStatus(){
  
	mqsilist $brokerName > $cmdsOnNodeLogFile   
	 
	 if grep  "BIP8019E" $cmdsOnNodeLogFile 
		then
			nodeRunningFlag='Stopped'
			printout "Node ($brokerName) Status : $nodeRunningFlag" 
	else
		nodeRunningFlag='Running'
		printout "Node ($brokerName) Status : $nodeRunningFlag"
	fi
	 
	rm $cmdsOnNodeLogFile
}
# Functions to check the current note status of the queue manager 
getQMGRCurrentStatus(){
 	
	dspmq -m $queueManager > qmgrstaus.tmp
	
	dspmqResult=$(<qmgrstaus.tmp)	

	qmgrStatus=$(sed -e 's#.*STATUS\(\)#\1#' <<< "$dspmqResult")

	if [[ $qmgrStatus == *"Running"* ]]; then
		qmgrRunningFlag="Running"
	else
		qmgrRunningFlag="Not Running"
	fi

	printout "QMGR ($queueManager) status : $qmgrRunningFlag" 
	
	rm qmgrstaus.tmp
}
# Functions to start queue manager
startQMGR(){

printout "Starting QMGR ($queueManager). Please wait for a while." 
strmqm $queueManager >> $deploymentLogPath > /dev/null 2>&1
}
# Functions to stop queue manager
stopQMGR(){
printout "Stopping QMGR ($queueManager). Please wait for a while." 
endmqm $queueManager >> $deploymentLogPath

}
# Functions to check the availability of a file in the directory
checkFileExists(){
 	
	if [ ! -f $1 ]
		then
			fileAvailabilityStatus=0
		else
			fileAvailabilityStatus=1
	fi
}
# Functions to check and create directory
checkAndCreateDirectory(){

[ -d $1 ] || mkdir $1

}
# Functions to cleanup directory
cleanupDirectory(){
 
	printout "Cleaning the directory $1."
	
	cd $1
	rm -f * >> $deploymentLogPath
	cd $executionHomeDirectory
	
}

getCodeDescription(){
 
    posOneValue=$1
    case $posOneValue in
		0) echo "Un Available";;
		1) echo "Available";;
		*) echo "Unknown" ;;
    esac  
}
# Functions  for creating array
getArraySize(){

	arraySize=0;
	incomingArray=("$@")
    for i in "${incomingArray[@]}";
      do
		((arraySize++))
      done

echo  $arraySize 
}
# Functions to append logs to the existing log file
appendTempLogToParentLog(){

	cat $1  >> $2
	rm $1

}
# Functions to overright the properties of the provided bar files
overrideBusinessBarFiles(){

	printout "${bold} IS1 Bar File(s)] [$arraySize] [$IS1Bars] picked for overriding ${normal} "	

	barsOverridden=""
	barsNotOverridden=""

	for i in ${IS1BarsArray[*]}; do
         
		printout "Overriding now '$i.bar'"
		
		checkFileExists $i.bar  
		barFileExist=$fileAvailabilityStatus
		checkFileExists $i.prop  
		propFileExist=$fileAvailabilityStatus
		
		printout "$i.bar $(getCodeDescription $barFileExist)";
		printout "$i.prop $(getCodeDescription $propFileExist)";
		
		if [ $barFileExist -eq 1 ] && [ $propFileExist -eq 1 ]
		
		then
			printout "Bar and Prop files available. Proceeding with override."
			mqsiapplybaroverride -b  $i.bar -p $i.prop -o $i.bar -r >> $barOverridePropFilesLogPath
			barsOverridden+="[$i]"
			printout "Overriding '$i.bar' completed"
		else
			printout "Overriding '$i.bar' ${RED}failed${NC}. Check whether file(s) exist. "
			barsNotOverridden+="[$i]"
		fi
		
	done
	printout "Bars Overridden :$barsOverridden"
	printout "Bars Not Overridden : $barsNotOverridden"
	printout "$integrationServer1 Bars Override Ended "
}
# Functions to overright the properties of the provided bar files
overrideIS2BarFiles(){
	 
	printout "${bold}[IS2 Bar File(s)][$arraySize][$IS2Bars] picked for overriding.${normal} "
	
	barsOverridden=""
	barsNotOverridden=""
	 
	for i in ${IS2BarsArray[*]}; do
         
		printout "Overriding now '$i.bar'"
		
		checkFileExists $i.bar  
		barFileExist=$fileAvailabilityStatus
		checkFileExists $i.prop  
		propFileExist=$fileAvailabilityStatus
		
		printout "$i.bar $(getCodeDescription $barFileExist)";
		printout "$i.prop $(getCodeDescription $propFileExist)";
		
		if [ $barFileExist -eq 1 ] && [ $propFileExist -eq 1 ]
		
		then
			printout "Bar and Prop files available. Proceeding with override."
			mqsiapplybaroverride -b  $i.bar -p $i.prop -o $i.bar -r >> $barOverridePropFilesLogPath
			barsOverridden+="[$i]"
			printout "Overriding '$i.bar' completed"
		else
			printout "Overriding '$i.bar' ${RED}failed${NC}. Check whether file(s) exist. "
			#printout "Bar or Property file  ${RED}DOES NOT EXIST${NC}. Check if they exist in execution Home directory. Ignoring override."
			barsNotOverridden+="[$i]"
		fi
		
	done
	printout "Bars Overridden :$barsOverridden"
	printout "Bars Not Overridden : $barsNotOverridden"
	printout "$integrationServer2 Bars Override Ended "
}
# Functions to overright the properties of the provided bar files
overrideIS3BarFiles(){
			 
			printout "${bold}[IS3 Bar File(s)][$arraySize][$IS3Bars] picked for overriding.${normal} "

			barsOverridden=""
			barsNotOverridden=""
			
			for i in ${IS3BarsArray[*]}; do
				 
				printout "Overriding now '$i.bar'"

				checkFileExists $i.bar  
				barFileExist=$fileAvailabilityStatus
				checkFileExists $i.prop  
				propFileExist=$fileAvailabilityStatus
				
				printout "$i.bar $(getCodeDescription $barFileExist)";
				printout "$i.prop $(getCodeDescription $propFileExist)";
				
				if [ $barFileExist -eq 1 ] && [ $propFileExist -eq 1 ]
				
				then
					printout "Bar and Prop files available. Proceeding with override."
					mqsiapplybaroverride -b  $i.bar -p $i.prop -o $i.bar -r >> $barOverridePropFilesLogPath
					barsOverridden+="[$i]"
					printout "Overriding '$i.bar' completed"
				else
					printout "Overriding '$i.bar' ${RED}failed${NC}. Check whether file(s) exist. "
					barsNotOverridden+="[$i]"
				fi
				
			done
			printout "Bars Overridden :$barsOverridden"
			printout "Bars Not Overridden : $barsNotOverridden"
			printout "$integrationServer1 Bars Override Ended "
}
overrideIS4BarFiles(){
			 
			printout "${bold}[IS4 Bar File(s)][$arraySize][$IS4Bars] picked for overriding.${normal} "

			barsOverridden=""
			barsNotOverridden=""
			
			for i in ${IS4BarsArray[*]}; do
				 
				printout "Overriding now '$i.bar'"

				checkFileExists $i.bar  
				barFileExist=$fileAvailabilityStatus
				checkFileExists $i.prop  
				propFileExist=$fileAvailabilityStatus
				
				printout "$i.bar $(getCodeDescription $barFileExist)";
				printout "$i.prop $(getCodeDescription $propFileExist)";
				
				if [ $barFileExist -eq 1 ] && [ $propFileExist -eq 1 ]
				
				then
					printout "Bar and Prop files available. Proceeding with override."
					mqsiapplybaroverride -b  $i.bar -p $i.prop -o $i.bar -r >> $barOverridePropFilesLogPath
					barsOverridden+="[$i]"
					printout "Overriding '$i.bar' completed"
				else
					printout "Overriding '$i.bar' ${RED}failed${NC}. Check whether file(s) exist. "
					barsNotOverridden+="[$i]"
				fi
				
			done
			printout "Bars Overridden :$barsOverridden"
			printout "Bars Not Overridden : $barsNotOverridden"
			printout "$integrationServer4 Bars Override Ended "
}
overrideIS5BarFiles(){
			 
			printout "${bold}[IS5 Bar File(s)][$arraySize][$IS5Bars] picked for overriding.${normal} "

			barsOverridden=""
			barsNotOverridden=""
			
			for i in ${IS5BarsArray[*]}; do
				 
				printout "Overriding now '$i.bar'"

				checkFileExists $i.bar  
				barFileExist=$fileAvailabilityStatus
				checkFileExists $i.prop  
				propFileExist=$fileAvailabilityStatus
				
				printout "$i.bar $(getCodeDescription $barFileExist)";
				printout "$i.prop $(getCodeDescription $propFileExist)";
				
				if [ $barFileExist -eq 1 ] && [ $propFileExist -eq 1 ]
				
				then
					printout "Bar and Prop files available. Proceeding with override."
					mqsiapplybaroverride -b  $i.bar -p $i.prop -o $i.bar -r >> $barOverridePropFilesLogPath
					barsOverridden+="[$i]"
					printout "Overriding '$i.bar' completed"
				else
					printout "Overriding '$i.bar' ${RED}failed${NC}. Check whether file(s) exist. "
					barsNotOverridden+="[$i]"
				fi
				
			done
			printout "Bars Overridden :$barsOverridden"
			printout "Bars Not Overridden : $barsNotOverridden"
			printout "$integrationServer5 Bars Override Ended "
}
# Functions to colour code the output of the executions
getStatusMessage(){

	inputData=$1
    
    case $inputData in
		0) 
			inputData="${RED}Failed${NC}"
			echo $inputData
			;;
		1) 
			inputData="${GREEN}Sucess${NC}"
			echo $inputData
			;;
		2) 
			inputData="${RED}DOES NOT EXIST${NC}"
			echo $inputData
			;;
		3) 
			inputData="${GREEN}EXISTS${NC}"
			echo $inputData
			;;
		*) 
			inputData="Unknown"
			echo $inputData
			;;
    esac  
}

checkForEmptyString(){
	if [ -z "$1" ]
	then
		  echo "None"
	else
		  echo "$1"
	fi
}

outputDeploymentStatus(){

	printout "Deployed $(checkForEmptyString $1). Ignored $(checkForEmptyString $2)"

}

getFullTimeStamp(){
	fullTS=$(date '+%d/%m/%Y %H:%M:%S');
	
	echo "$fullTS"

}
getTimeStamp(){
  date +"%T" 
  
}
logMemoryStatus(){

	if [ ! -f $freememLogPath ]; then
		 echo "TimeStamp,MemBefore,MemAfter,BarFileName" > $freememLogPath
	fi
	echo "[$(getFullTimeStamp)]$1,$2,$3,$4"  >> $freememLogPath
 
}
#Get the server memory
getFreeMemoryInMegaBytes(){

	um=`svmon -G | head -2|tail -1| awk {'print $3'}`
	um=`expr $um / 256`
	tm=`lsattr -El sys0 -a realmem | awk {'print $2'}`
	tm=`expr $tm / 1000`
	fm=`expr $tm - $um`
	
	echo "$fm"
}
# Function to Deploy the bar files in integration node
deployBarFiles(){

	printout "Activity Triggered " "[${FUNCNAME[0]}]"
	
	IFS=',' read -r -a IS1BarsArray <<< "$IS1Bars"
	arraySize=$(getArraySize ${IS1BarsArray[@]})
	
	if [ $arraySize = "0" ]; then
	   printout "${bold}[$arraySize] IS1 Barfiles picked for deployment.${normal} Ignoring deployment."
	else
		deployIS1BarFiles
	fi
		
	IFS=',' read -r -a IS2BarsArray <<< "$IS2Bars"
	arraySize=$(getArraySize ${IS2BarsArray[@]})
	
	if [ $arraySize = "0" ]; then
	  printout "${bold}[$arraySize] IS2 Barfiles picked for deployment.${normal} Ignoring deployment."
	else
		deployIS2BarFiles
	fi
	
	
	IFS=',' read -r -a IS3BarsArray <<< "$IS3Bars"
	arraySize=$(getArraySize ${IS3BarsArray[@]})
	
	if [ $arraySize = "0" ]; then
	  printout "${bold}[$arraySize] IS3 Barfiles picked for deployment.${normal} Ignoring deployment."
	else
		deployIS3BarFiles
	fi
	
	IFS=',' read -r -a IS4BarsArray <<< "$IS4Bars"
	arraySize=$(getArraySize ${IS3BarsArray[@]})
	
	if [ $arraySize = "0" ]; then
	  printout "${bold}[$arraySize] IS4 Barfiles picked for deployment.${normal} Ignoring deployment."
	else
		deployIS4BarFiles
	fi
	
	IFS=',' read -r -a IS5BarsArray <<< "$IS5Bars"
	arraySize=$(getArraySize ${IS5BarsArray[@]})
	
	if [ $arraySize = "0" ]; then
	  printout "${bold}[$arraySize] IS5 Barfiles picked for deployment.${normal} Ignoring deployment."
	else
		deployIS5BarFiles
	fi
}
# Deploy the bar files in integration node
deployIS1BarFiles(){
	
	printout "${bold}[$arraySize] IS1 Barfiles [$IS1Bars] picked for deployment.${normal}"

	counter=1
	barsDeployed=""
	barsNotDeployed=""
	printout "IS1 Deployment Started on node ($brokerName)."
	for i in ${IS1BarsArray[*]}; do
		checkFileExists $i.bar  
		barFileExist=$fileAvailabilityStatus
		if [ $barFileExist -eq 1 ]  
		then
			tmpLogFile="$i.bar.log.tmp"
			barFileName="$i.bar"
			
			freeMemBefore=$(getFreeMemoryInMegaBytes)
 			
			mqsideploy $brokerName -e $IS1 -a $barFileName -w $deploymentWaitTime  >> $tmpLogFile
			
			freeMemAfter=$(getFreeMemoryInMegaBytes)
			
			logMemoryStatus $IS1 $freeMemBefore $freeMemAfter $barFileName 
			
			if grep  "BIP1092I" $tmpLogFile 
				then
					printout "Bar ${counter} $(getStatusMessage 1) : ($i.bar) Deployed"  
					barsDeployed+="[$i]"
				else
					printout "Bar ${counter} $(getStatusMessage 0) : ($i.bar) Not Deployed. Check log '$deploymentLogPath'."   
					barsNotDeployed+="[$i]"
			fi
			
			appendTempLogToParentLog  $tmpLogFile $deploymentLogPath
			
		else
			printout "Bar ${counter} $(getStatusMessage 0) : ($i.bar) Does not exist. Check in execution Home directory."
			barsNotDeployed+="[$i]"
		fi
		
		((counter++))
	done
	
	outputDeploymentStatus "$barsDeployed" "$barsNotDeployed"
}
# Deploy the bar files in integration node
deployIS2BarFiles(){
	
	printout "${bold}[$arraySize] IS2 Barfiles [$IS2Bars] picked for deployment.${normal}"

	counter=1
	barsDeployed=""
	barsNotDeployed=""
	printout "IS2 Deployment Started on node ($brokerName)."
	for i in ${IS2BarsArray[*]}; do
		checkFileExists $i.bar  
		barFileExist=$fileAvailabilityStatus
		if [ $barFileExist -eq 1 ]  
		then
			tmpLogFile="$i.bar.log.tmp"
			barFileName="$i.bar"
			
			freeMemBefore=$(getFreeMemoryInMegaBytes)
 			
			mqsideploy $brokerName -e $IS2 -a $barFileName -w $deploymentWaitTime  >> $tmpLogFile
			
			freeMemAfter=$(getFreeMemoryInMegaBytes)
			
			logMemoryStatus $IS2 $freeMemBefore $freeMemAfter $barFileName 
			
			if grep  "BIP1092I" $tmpLogFile 
				then
					printout "Bar ${counter} $(getStatusMessage 1) : ($i.bar) Deployed"  
					barsDeployed+="[$i]"
				else
					printout "Bar ${counter} $(getStatusMessage 0) : ($i.bar) Not Deployed. Check log '$deploymentLogPath'."   
					barsNotDeployed+="[$i]"
			fi
			
			appendTempLogToParentLog  $tmpLogFile $deploymentLogPath
			
		else
			printout "Bar ${counter} $(getStatusMessage 0) : ($i.bar) Does not exist. Check in execution Home directory."
			barsNotDeployed+="[$i]"
		fi
		
		((counter++))
	done
	
	outputDeploymentStatus "$barsDeployed" "$barsNotDeployed"
}
# Deploy the bar files in integration node
deployIS3BarFiles(){
	
	printout "${bold}[$arraySize] IS3 Barfiles [$IS3Bars] picked for deployment.${normal}"

	counter=1
	barsDeployed=""
	barsNotDeployed=""
	printout "IS3 Deployment Started on node ($brokerName)."
	for i in ${IS3BarsArray[*]}; do
		checkFileExists $i.bar  
		barFileExist=$fileAvailabilityStatus
		if [ $barFileExist -eq 1 ]  
		then
			tmpLogFile="$i.bar.log.tmp"
			barFileName="$i.bar"
			
			freeMemBefore=$(getFreeMemoryInMegaBytes)
 			
			mqsideploy $brokerName -e $IS3 -a $barFileName -w $deploymentWaitTime  >> $tmpLogFile
			
			freeMemAfter=$(getFreeMemoryInMegaBytes)
			
			logMemoryStatus $IS3 $freeMemBefore $freeMemAfter $barFileName 
			
			if grep  "BIP1092I" $tmpLogFile 
				then
					printout "Bar ${counter} $(getStatusMessage 1) : ($i.bar) Deployed"  
					barsDeployed+="[$i]"
				else
					printout "Bar ${counter} $(getStatusMessage 0) : ($i.bar) Not Deployed. Check log '$deploymentLogPath'."   
					barsNotDeployed+="[$i]"
			fi
			
			appendTempLogToParentLog $tmpLogFile $deploymentLogPath
			
		else
			printout "Bar ${counter} $(getStatusMessage 0) : ($i.bar) Does not exist. Check in execution Home directory."
			barsNotDeployed+="[$i]"
		fi
		
		((counter++))
	done
	
	outputDeploymentStatus "$barsDeployed" "$barsNotDeployed"
}
 # Deploy the bar files in integration node
deployIS4BarFiles(){
	
	printout "${bold}[$arraySize] IS4 Barfiles [$IS4Bars] picked for deployment.${normal}"

	counter=1
	barsDeployed=""
	barsNotDeployed=""
	printout "IS4 Bars Deployment Started on node ($brokerName)."
	for i in ${IS2BarsArray[*]}; do
		checkFileExists $i.bar  
		barFileExist=$fileAvailabilityStatus
		if [ $barFileExist -eq 1 ]  
		then
			tmpLogFile="$i.bar.log.tmp"
			barFileName="$i.bar"
			
			freeMemBefore=$(getFreeMemoryInMegaBytes)
 			
			mqsideploy $brokerName -e $IS4 -a $barFileName -w $deploymentWaitTime  >> $tmpLogFile
			
			freeMemAfter=$(getFreeMemoryInMegaBytes)
			
			logMemoryStatus $IS4 $freeMemBefore $freeMemAfter $barFileName 
			
			if grep  "BIP1092I" $tmpLogFile 
				then
					printout "Bar ${counter} $(getStatusMessage 1) : ($i.bar) Deployed"  
					barsDeployed+="[$i]"
				else
					printout "Bar ${counter} $(getStatusMessage 0) : ($i.bar) Not Deployed. Check log '$deploymentLogPath'."   
					barsNotDeployed+="[$i]"
			fi
			
			appendTempLogToParentLog $tmpLogFile $deploymentLogPath
			
		else
			printout "Bar ${counter} $(getStatusMessage 0) : ($i.bar) Does not exist. Check in execution Home directory."
			barsNotDeployed+="[$i]"
		fi
		
		((counter++))
	done
	
	outputDeploymentStatus "$barsDeployed" "$barsNotDeployed"
}
# Deploy the bar files in integration node
deployIS5BarFiles(){
	
	printout "${bold}[$arraySize] IS5 Barfiles [$IS5Bars] picked for deployment.${normal}"

	counter=1
	barsDeployed=""
	barsNotDeployed=""
	printout "IS5 Deployment Started on node ($brokerName)."
	for i in ${IS5BarsArray[*]}; do
		checkFileExists $i.bar  
		barFileExist=$fileAvailabilityStatus
		if [ $barFileExist -eq 1 ]  
		then
			tmpLogFile="$i.bar.log.tmp"
			barFileName="$i.bar"
			
			freeMemBefore=$(getFreeMemoryInMegaBytes)
 			
			mqsideploy $brokerName -e $IS5 -a $barFileName -w $deploymentWaitTime  >> $tmpLogFile
			
			freeMemAfter=$(getFreeMemoryInMegaBytes)
			
			logMemoryStatus $IS5 $freeMemBefore $freeMemAfter $barFileName 
			
			if grep  "BIP1092I" $tmpLogFile 
				then
					printout "Bar ${counter} $(getStatusMessage 1) : ($i.bar) Deployed"  
					barsDeployed+="[$i]"
				else
					printout "Bar ${counter} $(getStatusMessage 0) : ($i.bar) Not Deployed. Check log '$deploymentLogPath'."   
					barsNotDeployed+="[$i]"
			fi
			
			appendTempLogToParentLog $(getFullTimeStamp) $tmpLogFile $deploymentLogPath
			
		else
			printout "Bar ${counter} $(getStatusMessage 0) : ($i.bar) Does not exist. Check in execution Home directory."
			barsNotDeployed+="[$i]"
		fi
		
		((counter++))
	done
	
	outputDeploymentStatus "$barsDeployed" "$barsNotDeployed"
}
#set the global variables
setGlobalVariables(){

# Global Variables

dt=$(date '+%d/%m/%Y %H:%M:%S');
PROP_FILE_NAME=app.properties 
brokerName=""
IS1=""
IS2=""
IS3=""
IS4=""
IS5=""
IS1Bars=""
IS2Bars=""
IS3Bars=""
IS4Bars=""
IS5Bars=""
deploymentWaitTime=""
dataSources=""
dataSourcesLogPath=""
queueCreateScriptPath=""
queueCreateLogPath=""
deploymentLogPath=""
nodeRunningFlag='Running'
qmgrRunningFlag='Running'
cmdsOnNodeLogFile=/var/mqm/deployment/nodestatus.tmp
brokerBackupLocation=""
fileAvailabilityStatus=""
barOverridePropFilePath=""
barOverridePropFilesLogPath=""
executionHomeDirectory=""
hostname=""
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color mandatory to end the colour. 
irstid=1000
bold=$(tput bold)
normal=$(tput sgr0)
upPortsArray=()
downPortsArray=() 
freememLogPath=""



printout "Automated Deployment ${GREEN}Started${NC}."
printout "Activity Triggered " "[${FUNCNAME[0]}]"

}
#load the properties file and print the status
loadPropertiesAndPrintStatus(){

    printout "Activity Triggered " "[${FUNCNAME[0]}]"
	
	if [ -f "$PROP_FILE_NAME" ]
	then
	  printout "File [$PROP_FILE_NAME] ${GREEN}FOUND${NC}. Fetching Keys and storing appropriate values in script."
	  
	  brokerName=$(getProperty brokerName)
	  queueManager=$(getProperty queueManager)
	  IS1=$(getProperty IS1)
	  IS2=$(getProperty IS2)
	  IS3=$(getProperty IS3)
	  IS4=$(getProperty IS4)
	  IS5=$(getProperty IS5)
	  IS1Bars=$(getProperty IS1Bars)
	  IS2Bars=$(getProperty IS2Bars)
	  IS3Bars=$(getProperty IS3Bars)
	  IS4Bars=$(getProperty IS4Bars)
	  IS5Bars=$(getProperty IS5Bars)
	  deploymentWaitTime=$(getProperty deploymentWaitTime)
	  dataSources=$(getProperty dataSources)
	  dsnCheckLogPath=$(getProperty dsnCheckLogPath)
	  queueCreateScriptPath=$(getProperty queueCreateScriptPath)
	  queueCreateLogPath=$(getProperty queueCreateLogPath)
	  deploymentLogPath=$(getProperty deploymentLogPath)
	  brokerBackupLocation=$(getProperty brokerBackupLocation)
	  brokerBackupLogFile=$(getProperty brokerBackupLog)
	  barOverridePropFilePath=$(getProperty barOverridePropFilePath)
	  barOverridePropFilesLogPath=$(getProperty barOverridePropFilesLogPath)
	  executionHomeDirectory=$(getProperty executionHomeDirectory)
	  endpointsPropFilePath=$(getProperty endpointsPropFilePath)
	  freememLogPath=$(getProperty freememLogPath)
	  
	  portsCheck=$(getProperty portsCheck)
	  portCheckWaitTime=$(getProperty portCheckWaitTime)
	 
	  printout "Property - Broker Name :$brokerName"
	  printout "Property - Queue Manager Name : ${queueManager}"
	  printout "Property - Integration server (IS1) : ${IS1}"
	  printout "Property - Integration server (IS2) : ${IS2}"
	  printout "Property - Integration server (IS3) : ${IS3}"
	  printout "Property - Integration server (IS4) : ${IS4}"
	  printout "Property - Integration server (IS5) : ${IS5}"
	  printout "Property - IS1 Barfiles : ${IS1Bars}"
	  printout "Property - IS2 Barfiles : ${IS2Bars}"
	  printout "Property - IS3 Barfiles : ${IS3Bars}"
	  printout "Property - IS4 Barfiles : ${IS4Bars}"
	  printout "Property - IS5 Barfiles : ${IS5Bars}"
	  printout "Property - Deployment Wait Time : ${deploymentWaitTime}"
	  printout "Property - Data Sources : ${dataSources}"
	  printout "Property - DSN Log path : ${dsnCheckLogPath}"
	  printout "Property - Queue Creation Script path : ${queueCreateScriptPath}"
	  printout "Property - Queue Creation Log path : ${queueCreateLogPath}"
	  printout "Property - Deployment Log path : ${deploymentLogPath}"
	  printout "Property - Broker Backup Location : ${brokerBackupLocation}"
	  printout "Property - Broker Backup Log path : ${brokerBackupLogFile}"
	  printout "Property - Bar Files override property files path : ${barOverridePropFilePath}"
	  printout "Property - Bar Files override Log path : ${barOverridePropFilesLogPath}"
	  printout "Property - Artefacts Home directory : ${executionHomeDirectory}"
	  printout "Property - endpointsPropFilePath : ${endpointsPropFilePath}"
	  printout "Property - Ports to be Checked : ${portsCheck}"
	  printout "Property - Ports check wait-time (Sec) : ${portCheckWaitTime}"
	  printout "Property - Free Memory Log path : ${freememLogPath}"
	  
	else
	  printout "$PROP_FILE_NAME ${RED}NOT FOUND${NC}. Exiting the script. Further statements will not execute"
	  exit 1
	fi
}
#stop integration node
stopNode(){

	printout "Activity Triggered " "[${FUNCNAME[0]}]"
	getQMGRCurrentStatus
	getNodeCurrentStatus
	 
	if [ "$qmgrRunningFlag" = "Running" ]
		then
			if [ $nodeRunningFlag = "Running" ]
				then
				printout "Node ($brokerName) is being stopped. Please wait."
				mqsistop $brokerName > $cmdsOnNodeLogFile
				#getNodeCurrentStatus
				printout "Node ($brokerName) is stopped."
				 
			    else
				printout "Node ($brokerName) is already stopped. No Action taken."
			fi
	fi
	if [ "$qmgrRunningFlag" = "Not Running" ]
		then
			startQMGR
			printout "Node ($brokerName) is being stopped. Please wait."
			mqsistop $brokerName > $cmdsOnNodeLogFile
			stopQMGR
	fi
	
}
#backup integration node
backupNode(){
	 
    printout "Activity Triggered " "[${FUNCNAME[0]}]"
	current_time=$(date "+%Y.%m.%d-%H.%M.%S")
	checkAndCreateDirectory $brokerBackupLocation
	 
	cleanupDirectory $brokerBackupLocation
	# This cleanup can be removed, based on the space, as timestamp gets apended
	
	
	printout "Backing up Node $brokerName at location : $brokerBackupLocation"

	brokerBackupFileName=$brokerName'_'$current_time.zip

	mqsibackupbroker $brokerName -d $brokerBackupLocation  -a  $brokerBackupFileName -v $brokerBackupLogFile > $brokerBackupLogFile
 
	checkFileExists  $brokerBackupFileName 
	
	printout "Broker backup created. Filename [$brokerBackupFileName]"
}
 #start integration node
startNode(){
 
	printout "Activity Triggered " "[${FUNCNAME[0]}]"
	getNodeCurrentStatus
	 
	printout "Checking associated QMGR ($queueManager) status."
	getQMGRCurrentStatus
	 
	if [ "$qmgrRunningFlag" = "Running" ]
		then
			if [ $nodeRunningFlag = "Stopped" ]
				then
				printout "Node ($brokerName) is Starting. Please wait."
				mqsistart $brokerName > $cmdsOnNodeLogFile
				getNodeCurrentStatus 
			fi
	fi
	
	if [ "$qmgrRunningFlag" = "Not Running" ]
		then
			startQMGR
			printout "Node ($brokerName)  is Starting. Please wait."
			mqsistart $brokerName > $cmdsOnNodeLogFile
			getNodeCurrentStatus
	fi
}
#Create queues
createQueues(){
	printout "Activity Triggered " "[${FUNCNAME[0]}]"
	
	runmqsc $queueManager < $queueCreateScriptPath  > $queueCreateLogPath

	 qExists=$(grep -c exists $queueCreateLogPath)
	 qCreated=$(grep -c created $queueCreateLogPath)
	 
	 printout "Queues Already Exists in QM ($queueManager) : $qExists" 
	 printout "Queues Newly created  QM ($queueManager): $qCreated" 
}
 
checkDSNConnectivity(){
 
    printout "Activity Triggered " "[${FUNCNAME[0]}]"
	 
	rm -f $dsnCheckLogPath >> $dsnCheckLogPath

	IFS=',' read -r -a dataSourcesArray <<< "$dataSources"
	
	arraySize=$(getArraySize ${dataSourcesArray[@]})
	
	tmpLogFile="dsnCheckLogPath.tmp" 
	
	printout "${bold}DSN(s) [$arraySize] [$dataSources] picked for Checking.${normal}"
	counter=1
	for i in ${dataSourcesArray[*]}; do
         
		mqsicvp   $brokerName  -n $i   &> $tmpLogFile
		 
		
		if grep -R "BIP8272E" $tmpLogFile
		
		then
			printout "DSN ${counter} $(getStatusMessage 0): [$i]. Check log [$dsnCheckLogPath]"
		 
		else
			printout "DSN ${counter} $(getStatusMessage 1): [$i] "
		fi
		((counter++))
		
		appendTempLogToParentLog $tmpLogFile $dsnCheckLogPath
		
	done
}
 
overrideBarFilesWithPropFiles(){
    printout "Activity Triggered " "[${FUNCNAME[0]}]"
	rm -f $barOverridePropFilesLogPath

	
	IFS=',' read -r -a IS1BarsArray <<< "$IS1Bars"
	arraySize=$(getArraySize ${IS1BarsArray[@]})
	
	if [ $arraySize = "0" ]; then
	   printout "No IS1 Bars found for overriding. Ignoring for IS1"
	else
		overrideIS1BarFiles
	fi
	
	IFS=',' read -r -a IS2BarsArray <<< "$IS2Bars"
	arraySize=$(getArraySize ${IS2BarsArray[@]})
	
	if [ $arraySize = "0" ]; then
	   printout "No IS2 Bars found for overriding. Ignoring for IS2"
	else
		overrideIS2BarFiles
	fi
	
	IFS=',' read -r -a IS3BarsArray <<< "$IS3Bars"
	arraySize=$(getArraySize ${IS3BarsArray[@]})
	
	if [ $arraySize = "0" ]; then
	   printout "No IS3 Bars found for overriding. Ignoring for IS3"
	else
		overrideIS3BarFiles
	fi
	
	IFS=',' read -r -a IS4BarsArray <<< "$IS4Bars"
	arraySize=$(getArraySize ${IS4BarsArray[@]})
	
	if [ $arraySize = "0" ]; then
	   printout "No IS4 Bars found for overriding. Ignoring for IS3"
	else
		overrideIS3BarFiles
	fi
	
	IFS=',' read -r -a IS5BarsArray <<< "$IS5Bars"
	arraySize=$(getArraySize ${IS5BarsArray[@]})
	
	if [ $arraySize = "0" ]; then
	   printout "No IS5 Bars found for overriding. Ignoring for IS3"
	else
		overrideIS5BarFiles
	fi
}


validateEndpoints(){
printout "Activity Triggered " "[${FUNCNAME[0]}]"

IFS=$'\r\n' GLOBIGNORE='*' command eval  'endpointsArray=($(cat $endpointsPropFilePath))'

printout "Using Endpoints property file : $endpointsPropFilePath"


ipAddOfHost="$(hostname --ip-address)"
printout  "Total Endpoints found: [ ${#endpointsArray[@]} ]. Testing on host (${HOSTNAME} - $ipAddOfHost)"

i=0
while [ $i -lt ${#endpointsArray[@]} ] 

	do
		endpoint="${endpointsArray[$i]}"
    
		if curl -k --output /dev/null --silent --head --fail "${endpoint//ipaddress/$ipAddOfHost}"; then
			printout "EP $i ${GREEN}Success${NC} : ${endpointsArray[$i]}"
		else
			printout "EP $i ${RED}Failed${NC} : ${endpointsArray[$i]}"
		fi
		((i++))
done
} 

sleepForPortCheck(){
 
	dt=$(date '+%d/%m/%Y %H:%M:%S');
	for i in {2..1}; do echo -ne "[$dt] :  Port Check starts in (Sec) $i"'\r'; sleep 1; done; echo 
 
}

portsChecked(){
	openStatus=$2
   
    case $openStatus in
		 
		0)downPortsArray+=($1);; 
		1)upPortsArray+=($1);; 
		*);;
		 
    esac  
}
 

checkPorts(){
	
    printout "Activity Triggered " "[${FUNCNAME[0]}]"
	arraySize=$(getArraySize ${portsCheckArray[@]})
	IFS=',' read -r -a portsCheckArray <<< "$portsCheck"
	printout "${bold}Ports(s) [$arraySize] [$portsCheck] picked for Checking.${normal}"
	
	sleepForPortCheck $portCheckWaitTime 
	
	counter=1
	for i in ${portsCheckArray[*]}; do
         
		$(>/dev/tcp/localhost/$i) &>/dev/null && portsChecked "$i" "1" || portsChecked "$i" "0"
		  
		((counter++))
	done
 
	printout " Up Ports count: ${#upPortsArray[@]}"
	printout " Down Ports count:  ${#downPortsArray[@]}"
	 
}

clearScreen(){
    clear
}


#---------Calling Routines------
setGlobalVariables
loadPropertiesAndPrintStatus
stopNode  	
backupNode
startNode  
createQueues
# checkDSNConnectivity
overrideBarFilesWithPropFiles
deployBarFiles
# checkPorts
# validateEndpoints   

#---------Calling Routines------
 
  

