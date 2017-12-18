######################################################
#
# README
#
######################################################



######################################################
#
# VARIABLES (Configuration)
#
######################################################


ANDROIDIP="10.114.1.240"   #IP of android phone sending sms
SMSPORT="9090"
SENDTONUMBER="0992460301" #Phone number to send sms to
SMSAPI="wget -q -O ./tmp/sendsms.tmp http://${ANDROIDIP}:${SMSPORT}/sendsms?phone=${SENDTONUMBER}\&text="
RIGLIST=( 10.114.1.200 10.114.1.201) # List of IPv4s of your EthOS rigs

NOWT=$(date '+%d/%m/%Y %H:%M:%S')
LOG="/home/pi/minemonitor/log.txt"

######################################################
#
# FUNCTIONS
#
######################################################


######################################################
#
# M A I N
#
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
                        MESSAGE="\"Could not ping ${i}, rig not connected to network or frozen.\""
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
