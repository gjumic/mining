#!/bin/bash
######################################################
# ETHOS GPU WATCHDOG by Stormer
######################################################
# Main function of this script is to monitor gpu.
# If your gpu crashes it will log it and reboot your mining rig.
# Additional functions are:
# Check if rig is running at least 10min (default) before minitoring is allowed
# Skip gpu check if mining is disallowed (in case you are working on rig and dont want it to be rebooted by this)
# Log cleaner
# Customizable throu variables
#
# Install guide:
# 1. Save file to desired location
# 2. Give execute premission to file with "chmod +x gpu.sh"
# 3. Modify script configuration via variables to suit your needs then save and exit.
# 4. Execute once with sudo so script adds itself to cronjob list. 
# Example "sudo /home/ethos/gpu.sh"
# Thats it, your script will add itself and run every x minutes depending on configuration.
#
# For all feedback contact me on jumic.goran[AT]gmail.com
######################################################
# If you have found this script useful please donate BTC or ETH to following adresses.
# This will give me more motivation to work on this and many more scripts:
# BTC = 1Dqa4Exdc2cfeMuhZ7Pnf9ri253UtbhsxY
# ETH = 0xe42fb03f179Fe4e11480D623e5C40eA070a6222F
######################################################
# VARIABLES (Configuration)
######################################################

REBOOT="true" # If this true it will log and reboot on gpu fail, else will just log
LOGGING="true" # if this true it will log hourly report to crash.log
HASH_RATE_MINIMUM="15" # Minimum hashrate per GPU, if drops below will trigger script. If your GPU hashes for example 30MH/s, you can put 20 here.
MEMORY_MHZ_MINIMUM="1000" # Minimum per GPU memory speed, if drops below will trigger script.
VOLTAGE_MINIMUM="0.6" # Minimum per GPU core voltage, if drops below will trigger script.
LOG="/home/ethos/crash.log" # Location where to write log file, folder must exist
LOGSIZE="1000" # You can change this number to make log file shorter or longer (how many lines)
CRONMINUTES="5" # How many minutes between each check (execution of this script)

######################################################
# M A I N
######################################################

# First check if the miner has had 10 minutes to start mining close the script if not.
if [[ `sed 's/\..*//' /proc/uptime` -lt "600" ]]; then
	exit 1
fi

# Lets get some information to work with.

HR=`tail -1 /var/run/ethos/miner_hashes.file`
allow=`cat /opt/ethos/etc/allow.file`
error=`cat /var/run/ethos/status.file`
TMP=`grep ^temp: /var/run/ethos/stats.file | sed 's/temp://' | sed 's/\...//g'`
rig=`grep rack_loc: /var/run/ethos/stats.file | sed 's/rack_loc://'`
MS=`grep ^memstates: /var/run/ethos/stats.file | sed 's/memstates://'`
MSPEED=`grep ^mem: /var/run/ethos/stats.file | sed 's/mem://'`
VOLTAGE=`grep ^voltage: /var/run/ethos/stats.file | sed 's/voltage://'`
DT=`date +"%D %T"`
gpu="0"
GPUCOUNT=$(cat /var/run/ethos/gpucount.file)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'


touch $LOG
chown ethos:ethos $LOG

# This will add this script to crontab
ME=$(readlink -f "$0")
croninit="SHELL=/bin/bash"
( crontab -l | grep -v -F "$croninit" ; echo "$croninit" ) | crontab -
cronjob="*/$CRONMINUTES * * * * $ME"
( crontab -l | grep -v -F "$ME" ; echo "$cronjob" ) | crontab -

# This will check if sgminer is working and use its log

if  [ -f /tmp/sgminer.log ] && [ grep -q "DEAD"  /tmp/sgminer.log ] 
then 
	# Action to take if GPU crashed
	echo 	"######################################" | tee -a $LOG
	echo 	"Detected DEAD GPU or GPUS from sgminer log" | tee -a $LOG
	echo -e "$DT: RIG ${RED}CRASHED${NC} - $rig is restarting" | tee -a $LOG
	echo 	"######################################" | tee -a $LOG
	
	if [[ $REBOOT == "true" ]]; then
		# Here is the reboot command	
		/opt/ethos/bin/hard-reboot
		exit 1
	fi
fi


# Separate each hash into its own loop.
for i in ${HR[@]}; do 

# First Lets check the temp for an error code that will cancel the restart. 
if [[ `awk -v g=$((gpu+1)) '{print $g}' <<< ${TMP[@]}` == "511" ]] || [[ $error = "hardware error: possible gpu/riser/power failure" ]]; then
	echo "$DT: GPU$gpu on $rig needs hardware attention. $error" >> $LOG
	continue
fi

# Now test if the hash rate is 0 and that mining is allowed.
# Feel free to change $crash above to fit your needs.
if [[ $(bc <<< "$i < $HASH_RATE_MINIMUM") -eq 1 ]] && [[ $allow == "1" ]]; then DOREBOOT="true"; fi
if [[ $error == "gpu crashed: reboot required" ]] && [[ $allow == "1" ]]; then DOREBOOT="true"; fi
if [[ `awk -v s=$((gpu+1)) '{print $s}' <<< ${MS[@]}` == 0 ]] && [[ $allow == "1" ]]; then DOREBOOT="true"; fi
if [[ `awk -v s=$((gpu+1)) '{print $s}' <<< ${MSPEED[@]}` -lt $MEMORY_MHZ_MINIMUM ]] && [[ $allow == "1" ]]; then DOREBOOT="true"; fi
if [[ $(bc <<< "`awk -v s=$((gpu+1)) '{print $s}' <<< ${VOLTAGE[@]}` < $VOLTAGE_MINIMUM") -eq 1 ]] && [[ $allow == "1" ]]; then DOREBOOT="true"; fi

if [[ $DOREBOOT == "true" ]]; then
	# Action to take if GPU crashed
	echo 	"######################################" | tee -a $LOG
	echo -e "$DT: GPU$gpu ${RED}CRASHED${NC} - $rig is restarting" | tee -a $LOG
	echo -e "Status: $error" | tee -a $LOG
	echo -e "Hashes: $HR - minimum: ${YELLOW}$HASH_RATE_MINIMUM${NC}" | tee -a $LOG
	echo -e "MemStates: $MS" | tee -a $LOG
	echo -e "MemSpeeds: $MSPEED - minimum: ${YELLOW}$MEMORY_MHZ_MINIMUM${NC}" | tee -a $LOG
	echo -e "Voltages: $VOLTAGE - minimum: ${YELLOW}$VOLTAGE_MINIMUM${NC}" | tee -a $LOG
	echo -e "Temperatures: $TMP" | tee -a $LOG
	echo 	"######################################" | tee -a $LOG
	
	if [[ $REBOOT == "true" ]]; then
		# Here is the reboot command	
		/opt/ethos/bin/hard-reboot
		exit 1
	fi
fi

(( gpu++ ))
done

# This will give you an hourly log saying that things are working.
if [ $LOGGING == "true" ] && [ `date +"%M"` == "00" ]; then
	echo 	"######################################" | tee -a $LOG
	echo -e "$DT: $rig is ${GREEN}WORKING${NC}" | tee -a $LOG
	echo -e "Status: $error" | tee -a $LOG
	echo -e "Hashes: $HR - minimum: ${YELLOW}$HASH_RATE_MINIMUM${NC}" | tee -a $LOG
	echo -e "MemStates: $MS" | tee -a $LOG
	echo -e "MemSpeeds: $MSPEED - minimum: ${YELLOW}$MEMORY_MHZ_MINIMUM${NC}" | tee -a $LOG
	echo -e "Voltages: $VOLTAGE - minimum: ${YELLOW}$VOLTAGE_MINIMUM${NC}" | tee -a $LOG
	echo -e "Temperatures: $TMP" | tee -a $LOG
	echo 	"######################################" | tee -a $LOG
fi

# Lets not let logs get out of control and truncate them a bit.
echo "$(tail -n $LOGSIZE $LOG)" > $LOG
