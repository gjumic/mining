#!/bin/bash
#
# EthOS GPU Restart Script (by cYnIx)
# -----------------------------------------------------------------------------------
# This script will do something if a GPU crashed. Default acion is to log and reboot.
#
# v 0.9.3 visit http://thecynix.com/gpu.sh for the latest updates.
# 
# ----------------------------------------------------------------------------------
# Installation and Automation
# 1: Save all of this text as gpu.sh in /home/ethos 
# 2: Run chmod u+x /home/ethos/gpu.sh
# 3: Type sudo crontab -e into your terminal and paste this string in:
# 	*/1 * * * * /home/ethos/gpu.sh
# 4: Your done! You can review crash.log to see how often your rig reboots and why.
# with tail crash.log
#
# */1 is every 1 minute if you want to run this less often (ie your stoping the miner
# often) do */5 for every 5 minutes or */10 for every 10 minutes. I do not recommend
# running this less than every 15 minutes to prevent a total system freeze. 
#
# This script is well documented so you can modify it for your purposes.
#####################################################################################
# If you found this script useful please donate BitCoin to:
# BTC= 1G6DcU8GrK1JuXWEJ4CZL2cLyCT57r6en2
# or Etherium to:
# ETH= 0x42D23fC535af25babbbB0337Cf45dF8a54e43C37
#####################################################################################

crash="300" # if hashing < x log and reboot
logsize="1000" # only have last x lines in log
reboot="true" # if this false it will not reboot just log
loggood="true" # if this true it will log hourly report to crash.log
mspeedtreshold="900" # if memory clock of any card is less than this it will log and reboot
minimumvolt="0.5" # if gpu voltage drops below this it will log and reboot


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
touch /home/ethos/crash.log
chown ethos.ethos /home/ethos/crash.log

# Separate each hash into its own loop.
for i in ${HR[@]}; do 

# First Lets check the temp for an error code that will cancel the restart. 
if [[ `awk -v g=$((gpu+1)) '{print $g}' <<< ${TMP[@]}` == "511" ]] || [[ $error = "hardware error: possible gpu/riser/power failure" ]]; then
	echo "$DT: GPU$gpu on $rig needs hardware attention. $error" >> /home/ethos/crash.log
	continue
fi

# Now test if the hash rate is 0 and that mining is allowed.
# Feel free to change $crash above to fit your needs.
if [[ $(bc <<< "$i < $crash") -eq 1 ]] && [[ $allow == "1" ]]; then $DOREBOOT="true"; fi
if [[ $error == "gpu crashed: reboot required" ]] && [[ $allow == "1" ]]; then $DOREBOOT="true"; fi
if [[ `awk -v s=$((gpu+1)) '{print $s}' <<< ${MS[@]}` == 0 ]] && [[ $allow == "1" ]]; then $DOREBOOT="true"; fi
if [[ `awk -v s=$((gpu+1)) '{print $s}' <<< ${MSPEED[@]}` -lt $mspeedtreshold ]] && [[ $allow == "1" ]]; then $DOREBOOT="true"; fi
if [[ $(bc <<< "`awk -v s=$((gpu+1)) '{print $s}' <<< ${VOLTAGE[@]}` < $minimumvolt") -eq 1 ]] && [[ $allow == "1" ]]; then $DOREBOOT="true"; fi

if [[ $DOREBOOT == "true" ]]; then
	# Action to take if GPU crashed
	echo "######################################" >> /home/ethos/crash.log
	echo "$DT: GPU$gpu CRASHED - $rig is restarting" >> /home/ethos/crash.log
	echo "Status: $error" >> /home/ethos/crash.log
	echo "Hashes: $HR" >> /home/ethos/crash.log
	echo "MemStates: $MS" >> /home/ethos/crash.log
	echo "MemSpeeds: $MSPEED" >> /home/ethos/crash.log
	echo "Voltages: $VOLTAGE" >> /home/ethos/crash.log
	echo "Temperatures: $TMP" >> /home/ethos/crash.log
	echo "######################################" >> /home/ethos/crash.log
if [[ $reboot == "true" ]]; then
	# Here is the reboot command	
	/opt/ethos/bin/hard-reboot
fi
fi

(( gpu++ ))
done

# This will give you an hourly log saying that things are working.
if [ $loggood == "true" ] && [ `date +"%M"` == "00" ]; then
	echo "######################################" >> /home/ethos/crash.log
	echo "$DT: $rig is WORKING" >> /home/ethos/crash.log
	echo "Status: $error" >> /home/ethos/crash.logbash 
	echo "Hashes: $HR" >> /home/ethos/crash.log
	echo "MemStates: $MS" >> /home/ethos/crash.log
	echo "MemSpeeds: $MSPEED" >> /home/ethos/crash.log
	echo "Voltages: $VOLTAGE" >> /home/ethos/crash.log
	echo "Temperatures: $TMP" >> /home/ethos/crash.log
	echo "######################################" >> /home/ethos/crash.log
fi

# Lets not let logs get out of control and truncate them a bit.
echo "$(tail -n $logsize /home/ethos/crash.log)" > /home/ethos/crash.log



