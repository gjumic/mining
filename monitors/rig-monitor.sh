#!/bin/bash
######################################################
# README - 
######################################################
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
LOG="/opt/github/mining/monitors/log.txt" # Name and path to your log file, folder must exist

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
