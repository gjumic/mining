#!/bin/bash
######################################################
# README - ETHOS GPU WATCHDOG for sgminer by Stormer
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
# 3. Obtain root with "sudo su"
# 4. Edit "/opt/ethos/lib/minerprocess.php" and change this line:
# $miner_params['sgminer-gm'] = "-c /var/run/ethos/sgminer.conf";
# with
# $miner_params['sgminer-gm'] = "-c /var/run/ethos/sgminer.conf -L /tmp/sgminer.log";
# 5. Open crontab editor with "crontab -e"
# 6. Inside editor add "SHELL=/bin/bash" line
# 7. Inside editor add "*/5 * * * * /home/ethos/gpu-sgminer.sh" line
# You can change */5 to another number (default is ever 5th min and i dont recommend less then this) and change location to fit your needs
# 8. Reboot rig
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

LOGSIZE="1000" # only have last x lines in log
REBOOT="true" # if this false it will not reboot just log
LOGGING="true" # if this true it will log hourly report to crash.log
LOG="/home/ethos/crash-sgminer.log" # Location where to write log file, folder must exist

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

if grep -q "DEAD"  /tmp/sgminer.log
then 
   DOREBOOT="true";
fi


if [[ $DOREBOOT == "true" ]]; then
	# Action to take if GPU crashed
	echo 	"######################################" | tee -a $LOG
	echo -e "$DT: RIG ${RED}CRASHED${NC} - $rig is restarting" | tee -a $LOG
	echo 	"######################################" | tee -a $LOG
	
if [[ $REBOOT == "true" ]]; then
	# Here is the reboot command	
	/opt/ethos/bin/hard-reboot
fi
fi

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
