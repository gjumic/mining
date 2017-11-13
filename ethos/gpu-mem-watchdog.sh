#!/bin/bash


NOWT=$(date +"%D"-"%T")
echo "Sleeping 280 seconds, just in case!"
sleep 280
/opt/ethos/bin/update| grep -w mem>output.file
MEMORY="$( awk '$3 < 1000 {print $0;}' output.file )"
echo $MEMORY
	if  [[ -z $MEMORY ]]; 
	then 
		echo "None of the cards have less than 1000 mem speed"
		echo "GPU CHECK OK! $NOWT">>/root/rebooted.log
	else
		echo "$MEMORY" >> /root/rebooted.log 
		echo "GPU DOWN $NOWT -> REBOOT">>/root/rebooted.log 
		/opt/ethos/bin/hard-reboot
	fi
 
