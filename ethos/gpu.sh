#!/bin/bash
######################################################
# README - ETHOS GPU WATCHDOG v1.1 by Stormer
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
# 4. Open crontab editor with "crontab -e"
# 5. Inside editor add "SHELL=/bin/bash" line
# 6. Inside editor add "*/3 * * * * /home/ethos/gpu.sh" line
# You can change */3 to another number (default is ever 5th min and i dont recommend less then this)
#
# Props to Cynix from thecynix.com for givig me ideas for code with his monitor http://thecynix.com/gpu.txt
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
HASH_RATE_MINIMUM="350" # if hashing < x log and reboot
MEMORY_MHZ_MINIMUM="1000" # if memory clock of any card is less than this it will log and reboot
VOLTAGE_MINIMUM="0.6" # if gpu voltage drops below this it will log and reboot
LOG="/home/ethos/crash.log" # Location where to write log file, folder must exist
# ATM AMD GPUS ONLY
AUTOFAN="false" # enable auto-change of fan speed depending on average gpu temps BE CAREFULL, you can edit ranges of temps and fan speed below.

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
touch $LOG
chown ethos.ethos $LOG


if [[ $AUTOFAN == "true" ]]; then
		for ((I=0;I<GPUCOUNT;I++)); do
			GPUS[$I]=$I
	done
	
	tot=0
	for i in ${TMP[@]}; do
	let tot+=$i
	done
	
	AVTEMP=$(( $tot / $GPUCOUNT ))
	
	# Here you can edit ranges of temps and according fan speed for it
	if [ "$AVTEMP" -ge 20 -a "$AVTEMP" -le 40 ]; then SETFAN=50;
	elif [ "$AVTEMP" -ge 41 -a "$AVTEMP" -le 50 ]; then SETFAN=60;
	elif [ "$AVTEMP" -ge 51 -a "$AVTEMP" -le 60 ]; then SETFAN=70;
	elif [ "$AVTEMP" -ge 61 -a "$AVTEMP" -le 70 ]; then SETFAN=80;
	elif [ "$AVTEMP" -ge 71 -a "$AVTEMP" -le 100 ]; then SETFAN=90; fi

	echo "######################################" >> $LOG	
	echo "Average GPUs temperature: $AVTEMP" >> $LOG
	echo "Setting $SETFAN% fan speed for GPUs" >> $LOG
	echo "######################################" >> $LOG
	
	for I in "${!GPUS[@]}"; do
		HWMONDIR=$(echo /sys/class/drm/card$I/device/hwmon/* | grep -Poi "(?<=hwmon)(\d+)") 
		echo 1 > /sys/class/drm/card$I/device/hwmon/hwmon"$HWMONDIR"/pwm1_enable
		FAN=$(/bin/echo "$SETFAN * 2.55" | bc -l | awk '{printf "%.0f", $1}')
		echo "$FAN" > /sys/class/drm/card$I/device/hwmon/hwmon"$HWMONDIR"/pwm1
	done
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
	echo "######################################" >> $LOG
	echo "$DT: GPU$gpu CRASHED - $rig is restarting" >> $LOG
	echo "Status: $error" >> $LOG
	echo "Hashes: $HR" >> $LOG
	echo "MemStates: $MS" >> $LOG
	echo "MemSpeeds: $MSPEED" >> $LOG
	echo "Voltages: $VOLTAGE" >> $LOG
	echo "Temperatures: $TMP" >> $LOG
	echo "######################################" >> $LOG
if [[ $REBOOT == "true" ]]; then
	# Here is the reboot command	
	/opt/ethos/bin/hard-reboot
fi
fi

(( gpu++ ))
done

# This will give you an hourly log saying that things are working.
if [ $LOGGING == "true" ] && [ `date +"%M"` == "00" ]; then
	echo "######################################" >> $LOG
	echo "$DT: $rig is WORKING" >> $LOG
	echo "Status: $error" >> $LOGbash 
	echo "Hashes: $HR" >> $LOG
	echo "MemStates: $MS" >> $LOG
	echo "MemSpeeds: $MSPEED" >> $LOG
	echo "Voltages: $VOLTAGE" >> $LOG
	echo "Temperatures: $TMP" >> $LOG
	echo "######################################" >> $LOG
fi

# Lets not let logs get out of control and truncate them a bit.
echo "$(tail -n $LOGSIZE $LOG)" > $LOG
