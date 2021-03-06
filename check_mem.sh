#!/bin/bash

# check_mem v1.4
#
# v1.1 Copyright (C) 2012 Lukasz Gogolin (lukasz.gogolin@gmail.com)
# v1.2 2014 Modified by Aaron Roydhouse (aaron@roydhouse.com)
# v1.3 2015 Modified by Aaron Roydhouse (aaron@roydhouse.com)
# v1.4 2018 Modified by @DavidGoodwin, @eacmen, @whereisaaron

# Default percentage usage limits
CRITICAL=90
WARNING=80

usage() {
    echo "check_mem v1.4"
    echo ""
    echo "Usage: check_mem -w <warnlevel> -c <critlevel>"
    echo ""
    echo "  'warnlevel' and 'critlevel' are percentage values without a percent sign ('%')"
    echo "  e.g. check_mem -w 80 -c 90"
    echo ""
 }

while getopts "w:c:" o; do
    case "${o}" in
        c)
            CRITICAL=$(( ${OPTARG} + 0 ))
            ;;
        w)
            WARNING=$(( ${OPTARG} + 0))
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done


if [ $CRITICAL -lt 0 -o $CRITICAL -gt 100 -o $WARNING -lt 0 -o $WARNING -gt 100 -o $WARNING -gt $CRITICAL ]; then
    usage
    exit 1
fi


memTotal_k=$(awk '$1~/^MemTotal/{print $2}' /proc/meminfo )
memFree_k=$(awk '$1~/^MemFree/{print $2}' /proc/meminfo )
memBuffer_k=$(awk '$1~/^Buffers/{print $2}' /proc/meminfo )
memCache_k=$(awk '$1~/^Cached/{print $2}' /proc/meminfo )

memUsed_k=$(( $memTotal_k - $memFree_k - $memBuffer_k - $memCache_k ))
memUsedPrc=$(( ($memUsed_k * 100) / $memTotal_k ))

warn_m=$(( ((($memTotal_k*100)-($memTotal_k*(100-${WARNING})))/100)/1024 ))
crit_m=$(( ((($memTotal_k*100)-($memTotal_k*(100-${CRITICAL})))/100)/1024 ))

memTotal_m=$(($memTotal_k/1024))
memFree_m=$(($memFree_k/1024))
memUsed_m=$(($memUsed_k/1024))
memBuffer_m=$(($memBuffer_k/1024))
memCache_m=$(($memCache_k/1024))

minmax="0;$memTotal_m";
data="TOTAL=${memTotal_m}MB;;;$minmax USED=${memUsed_m}MB;$warn_m;$crit_m;$minmax CACHE=${memCache_m}MB;;;$minmax BUFFER=${memBuffer_m}MB;;;$minmax"

if [ "$memUsedPrc" -ge "${CRITICAL}" ]; then
    echo "MEMORY CRITICAL - Total: $memTotal_m MB - Used: $memUsed_m MB - $memUsedPrc% used!|$data"
    exit 2
elif [ "$memUsedPrc" -ge "${WARNING}" ]; then
    echo "MEMORY WARNING - Total: $memTotal_m MB - Used: $memUsed_m MB - $memUsedPrc% used!|$data"
    exit 1
else
    echo "MEMORY OK - Total: $memTotal_m MB - Used: $memUsed_m MB - $memUsedPrc% used|$data"
    exit 0
fi
