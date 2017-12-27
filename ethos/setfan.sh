#!/bin/bash
######################################################
# README - SETFAN for AMD gpus v1.0 by Stormer
######################################################
# FOR AMD CARDS ONLY
# Just put this script and give it execute rights with chmod
# Execute script with with how many percent you want fans to spin all gpus (./setfan.sh 50)
######################################################
# If you have found this script useful please donate BTC or ETH to following adresses.
# This will give me more motivation to work on this and many more scripts:
# BTC = 1Dqa4Exdc2cfeMuhZ7Pnf9ri253UtbhsxY
# ETH = 0xe42fb03f179Fe4e11480D623e5C40eA070a6222F
######################################################
GPUCOUNT=$(cat /var/run/ethos/gpucount.file)
SETFAN=$1

for ((I=0;I<GPUCOUNT;I++)); do
        GPUS[$I]=$I
        done

for I in "${!GPUS[@]}"; do
        HWMONDIR=$(echo /sys/class/drm/card$I/device/hwmon/* | grep -Poi "(?<=hwmon)(\d+)")
        echo 1 > /sys/class/drm/card$I/device/hwmon/hwmon"$HWMONDIR"/pwm1_enable
        FAN=$(/bin/echo "$SETFAN * 2.55" | bc -l | awk '{printf "%.0f", $1}')
        echo "$FAN" > /sys/class/drm/card$I/device/hwmon/hwmon"$HWMONDIR"/pwm1
done
