#!/bin/bash
######################################################
# README - ETHOS GPU WATCHDOG v1.0 by Stormer
######################################################
# Main function of this script is to monitor memory clock of your gpu memory.
# If your gpu crashes it will log it and reboot your mining rig.
# Additional functions are:
# Check if rig is running at least 10min (default) before minitoring is allowed
# Skip gpu check if mining is disallowed (in case you are working on rig and dont want it to be rebooted by this)
# Log cleaner
# Customizable throu variables
#
# Install guide:
# 1. Save file to desired location
# 2. Give execute premission to file with "chmod +x gpu-monitor.sh"
# 3. Obtain root with "sudo su"
# 4. Open crontab editor with "crontab -e"
# 5. Inside editor add "SHELL=/bin/bash" line
# 6. Inside editor add "*/5 * * * * /opt/gpu-watchdog/gpu-watchdog.sh" line (file location is example)
# You can change */5 to another number (default is ever 5th min and i dont recommend less then this)
#
# Props to Cynix from thecynix.com for givig me ideas for some parts for code with his monitor http://thecynix.com/gpu.txt
# For all feedback contact me on jumic.goran[AT]gmail.com
######################################################
# If you have found this script useful please donate BTC or ETH to following adresses.
# This will give me more motivation to work on this and many more scripts:
# BTC = 1Dqa4Exdc2cfeMuhZ7Pnf9ri253UtbhsxY
# ETH = 0xe42fb03f179Fe4e11480D623e5C40eA070a6222F
######################################################
# VARIABLES (Configuration)
######################################################


LOG="/opt/gpu-watchdog/log.txt" # Name and path to your log file, folder must exist
NOWT=$(date '+%d/%m/%Y %H:%M:%S') # Date and time format
MINUPTIME=600 #What minimum rig uptime should be to start checking
LOGSIZE=1000 #How mouch lines should log file contain (script leaves last x lines so log does not get too big)
GPUTRESHOLD=800 #If any gpu has mem lower than this it will reboot


#DO NOT CHANGE THIS LINES
ALLOWFILE=`cat /opt/ethos/etc/allow.file`
######################################################
# M A I N
######################################################



if [[ `sed 's/\..*//' /proc/uptime` -lt $MINUPTIME ]]; then
echo "RIG UPTIME LOW, SKIPPING GPU CHECK - $NOWT" >> $LOG
exit 1
fi

MEMORY="$( /opt/ethos/bin/update | grep -w "mem:" | sed 's/mem://' | sed "s/^[ \t]*//" )"
echo '###############################################' >> $LOG
echo "STARTING MEMORY SCAN - $NOWT" >> $LOG
echo '###############################################' >> $LOG

i=1
for m in $MEMORY
        do
        :
                if [ $ALLOWFILE != "1" ]; then
                        echo "MINING DISALLOWED, SKIPPING GPU CHECK" >> $LOG
                        break
                fi
                
                if  [[ $m -gt $GPUTRESHOLD ]];
                then
                        echo "GPUMEM$i: $m - CHECK OK!" >> $LOG
                else
                        echo "GPUMEM$i: $m - GPU DOWN! -> REBOOT" >> $LOG
                        nohup bash -c 'sleep 10; /opt/ethos/bin/hard-reboot' &
                fi
			((i++))
        done
echo '###############################################' >> $LOG
echo "FINISHED MEMORY SCAN - $NOWT" >> $LOG
echo '###############################################' >> $LOG

# Log cleaner
echo "$(tail -n $LOGSIZE ${LOG})" > $LOG
