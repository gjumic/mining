#!/bin/bash
######################################################
# README - ETHOS MINER RIG WATCHDOG v1.0 by Stormer
######################################################
# Main function of this script is to monitor if rigs are alive, if not it will send sms with warring which rig is offline.
# For now it just checks ping but soon more checks will come like ssh connection, rig status, temps, etc..
# This script should be run from some linux system (Raspberry Pi for me) in same network/subnet
#
# Install guide:
# 1. Save file to desired location
# 2. Give execute premission to file with "chmod +x rig-monitor.sh"
# 3. Open crontab editor with "crontab -e"
# 4. Inside editor add "SHELL=/bin/bash" line
# 5. Inside editor add "*/5 * * * * /opt/rig-monitor/rig-monitor.sh" line (file location is example)
# You can change */5 to another number (default is ever 5th min and i dont recommend less then this)
#
# YOU NEED SOME API FOR SENDING SMS, IM USING ANDOROID CELLPHONE IN MY NETWORK WITH REST SMS GATEWAY APP (sim card in cellphone)
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


RIGLIST=( 10.114.3.100 10.114.3.101 10.114.3.102 ) # List of IPv4s of your EthOS rigs
LOGSIZE=1000 #How mouch lines should log file contain (script leaves last x lines so log does not get too big)
NOWT=$(date '+%d/%m/%Y %H:%M:%S') # Date and time format
LOG="/home/pi/rig-monitor/log.txt" # Name and path to your log file, folder must exist

######################################################
# FUNCTIONS
######################################################


######################################################
# M A I N
######################################################

#Some prechecks
if [ -z $RIGLIST  ]; then echo "No provided IP"; exit 1; fi

#Ping every machine and notify if one of them is offline
echo '###############################################' >> $LOG
echo "STARTING CONNECTION CHECK - $NOWT" >> $LOG
echo '###############################################' >> $LOG
for i in "${RIGLIST[@]}"
        do
        :
		ssh -o PubkeyAuthentication=no -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no -o ChallengeResponseAuthentication=no -o StrictHostKeyChecking=no $i 2>&1 | grep "Permission denied"
                EXITCODE=$?
                if [ $EXITCODE != 0 ]; then
                        /usr/local/bin/telegram-send "Could not connect ${i}, rig not connected to network or frozen."
                        echo "Connection fail on ${i}"
                        echo "Connection check FAIL on ${i} $NOWT" >> $LOG
                else
                        echo "Connection OK on ${i}"
                        echo "Connection check OK on ${i} $NOWT" >> $LOG
                        #echo $EXITCODE
                fi
done
echo '###############################################' >> $LOG
echo "FINISHED CONNECTION CHECK - $NOWT" >> $LOG
echo '###############################################' >> $LOG

# Log cleaner
echo "$(tail -n $LOGSIZE ${LOG})" > $LOG
