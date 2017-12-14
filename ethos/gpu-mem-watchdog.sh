#!/bin/bash


NOWT=$(date '+%d/%m/%Y %H:%M:%S')
OUTPUT="/opt/gpu-watchdog/memory.output"
LOG="/opt/gpu-watchdog/log.txt"

echo "Sleeping 280 seconds, just in case!"
sleep 280
/opt/ethos/bin/update | grep -w mem > $OUTPUT
MEMORY="$( cat ${OUTPUT} | grep "mem:" | sed 's/mem://' | sed "s/^[ \t]*//" )"
echo '###############################################' >> $LOG
echo "STARTING MEMORY SCAN - $NOWT" >> $LOG
echo '###############################################' >> $LOG

for m in $MEMORY
        do
        :
                if  [[ $m -gt 1000 ]];
                then
                        echo "GPUMEM: $m" >> $LOG
                        echo "GPU CHECK OK! $NOWT" >> $LOG
                else
                        echo "GPUMEM: $m" >> $LOG
                        echo "GPU DOWN $NOWT -> REBOOT" >> $LOG
                        nohup bash -c 'sleep 10; /opt/ethos/bin/hard-reboot' &
                fi

        done
echo '###############################################' >> $LOG
echo "FINISHED MEMORY SCAN - $NOWT" >> $LOG
echo '###############################################' >> $LOG


echo "$(tail -n 500 ${LOG})" > $LOG
