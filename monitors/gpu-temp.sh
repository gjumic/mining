#!/bin/bash
######################################################
# README - MINING RIG GPU TEMPERATURE WATCHDOG v2.0 by Stormer
######################################################
# For all feedback contact me on jumic.goran[AT]gmail.com
######################################################
# If you have found this script useful please donate BTC or ETH to following adresses.
# This will give me more motivation to work on this and many more scripts:
# BTC = 1Dqa4Exdc2cfeMuhZ7Pnf9ri253UtbhsxY
# ETH = 0xe42fb03f179Fe4e11480D623e5C40eA070a6222F
######################################################
# VARIABLES (Configuration)
######################################################


RIGLIST=( 10.114.3.100 10.114.3.101 10.114.3.102 )
LOGSIZE=1000 #How mouch lines should log file contain (script leaves last x lines so log does not get too big)
NOWT=$(date '+%d/%m/%Y %H:%M:%S') # Date and time format
LOG="/home/pi/rig-monitor/temp-log.txt" # Name and path to your log file, folder must exist
MPOWER_IP="10.114.3.103"
MAX_TEMP=72 # IF TEMPERATURE GREATER THAN THIS VENTILATION WILL TURN ON
CHECK_EVERY=120 # HOW MANY SECONDS BETWEEN EACH CHECK
TURN_OFF_TIMEOUT=1200 # HOW MANY SECONDS WILL VENTILATION STILL CONTINUE TO WORK AFTER TEMPERATURES ARE BACK BELOW MAX_TEMP


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

######################################################
# FUNCTIONS
######################################################


######################################################
# M A I N
######################################################

#Some prechecks
if [ -z $RIGLIST  ]; then echo "No provided IP"; exit 1; fi

while true; do
	sleep $CHECK_EVERY
	echo '###############################################' >> $LOG
	echo "STARTING TEMPERATURE CHECK - $NOWT" >> $LOG
	echo '###############################################' >> $LOG
	for i in "${RIGLIST[@]}"
        do
        :
			TEMPS=($(sshpass -p 1 ssh user@$i "amd-info | grep Temp: | awk '{print \$12}'"))
			echo -e "-------------" >> $LOG 	
			echo -e "Checking Rig: ${YELLOW}$i${NC}" >> $LOG 	
			for t in ${TEMPS[@]}; do
				if [ $t -gt $MAX_TEMP ]; then
					echo -e "GPU Temp: ${RED}$t${NC}" >> $LOG 
					TURNON="true"
				else
					echo -e "GPU Temp: ${GREEN}$t${NC}" >> $LOG
					TURNON="false"
				fi 		
			done
	done
			
	echo -e "======================" >> $LOG	
	
	if [[ $TURNON == "true" ]]; then
		echo -e "${RED}High Temperature Detected${NC} on GPU -> Turning ON Ventilation" >> $LOG
		sshpass -p ubnt ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 ubnt@$MPOWER_IP "echo '1' > /proc/power/relay3"
		echo -e "Temperature Re-check in ${CHECK_EVERY} seconds" >> $LOG
		echo -e "======================" >> $LOG
		OFF_TIMER="true"
		continue
	else	
		if [[ $OFF_TIMER == "true" ]]; then 
			echo -e "${GREEN}All Temperatures are normal on GPUs -> Turning OFF Ventilation in ${TURN_OFF_TIMEOUT} seconds ${NC}" >> $LOG
			sleep $TURN_OFF_TIMEOUT
			sshpass -p ubnt ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 ubnt@$MPOWER_IP "echo '0' > /proc/power/relay3"
		else
			echo -e "${GREEN}All Temperatures are normal on GPUs -> Ventilation already OFF, continue...${NC}" >> $LOG
		fi		
		echo -e "Temperature Re-check in ${CHECK_EVERY} seconds" >> $LOG
		echo -e "======================" >> $LOG
		OFF_TIMER="false"
		continue
	fi	
	
echo '###############################################' >> $LOG
echo "FINISHED TEMPERATURE CHECK - $NOWT" >> $LOG
echo '###############################################' >> $LOG

echo "$(tail -n $LOGSIZE ${LOG})" > $LOG # Log cleaner
done
