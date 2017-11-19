#!/bin/bash


NOWT=$(date +"%D"-"%T")
echo "Sleeping 280 seconds, just in case!"
#sleep 280
/opt/ethos/bin/update | grep -w mem > /opt/tools/output.file
MEMORY="$( awk '$3 < 1000 {print $0;}' /opt/tools/output.file )"
echo $MEMORY
        if  [[ -z $MEMORY ]];
        then
                echo "None of the cards have less than 1000 mem speed"
                echo "GPU CHECK OK! $NOWT" >> /opt/tools/rebooted.log
        else
                echo "$MEMORY" >> /opt/tools/rebooted.log
                echo "GPU DOWN $NOWT -> REBOOT" >> /opt/tools/rebooted.log
                /opt/ethos/bin/hard-reboot
fi
