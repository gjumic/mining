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


ANDROIDIP="<IP OF ANDROID WHICH SENDS SMS>"   #IP of android phone sending sms
SMSPORT="<PORT ON ANDROID>"
SENDTONUMBER="<YOUR PHONE NUMBER>" #Phone number to send sms to
SMSAPI="curl -X PUT http://${ANDROIDIP}:${SMSPORT}/v1/sms/\?phone=${SENDTONUMBER}\&sim_slot=0\&message="
RIGLIST=( <IP LIST TO CHECH, SEPARATE WITH SPACE> ) # List of IPv4s of your EthOS rigs
LOGSIZE=1000 #How mouch lines should log file contain (script leaves last x lines so log does not get too big)
NOWT=$(date '+%d/%m/%Y %H:%M:%S') # Date and time format
LOG="/home/pi/minemonitor/log.txt" # Name and path to your log file, folder must exist

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
echo "STARTING PING CHECK - $NOWT" >> $LOG
echo '###############################################' >> $LOG
for i in "${RIGLIST[@]}"
        do
        :
                sudo ping -c 3 $i >/dev/null
                EXITCODE=$?
                if [ $EXITCODE != 0 ]; then
                        MESSAGE="Could%20not%20ping%20${i},%20rig%20not%20connected%20to%20network%20or%20frozen."
                        EXECSMS="$SMSAPI$MESSAGE"
                        eval $EXECSMS
                        echo "Ping fail on ${i}"
                        echo "Ping check FAIL on ${i} $NOWT" >> $LOG
                else
                        echo "Ping OK on ${i}"
                        echo "Ping check OK on ${i} $NOWT" >> $LOG
                        #echo $EXITCODE
                fi
done
echo '###############################################' >> $LOG
echo "FINISHED PING CHECK - $NOWT" >> $LOG
echo '###############################################' >> $LOG

# Log cleaner
echo "$(tail -n $LOGSIZE ${LOG})" > $LOG
