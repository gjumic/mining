#!/bin/bash

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
