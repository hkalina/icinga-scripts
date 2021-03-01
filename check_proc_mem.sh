#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File: check_proc_mem.sh
## Author : Denny <contact@dennyzhang.com>
## Modified by: Jan Kalina <jan.kalina@fantom.foundation>
## Description :
## --
##
## Link: https://www.dennyzhang.com/nagois_monitor_process_memory
##
## Created : <2014-10-25>
##-------------------------------------------------------------------

if [ "$1" = "-w" ] && [ "$2" -gt "0" ] && \
    [ "$3" = "-c" ] && [ "$4" -gt "0" ]; then
    pidPattern=${5?"specify how to get pid"}

    if [ "$pidPattern" = "--pidfile" ]; then
        pidfile=${6?"pidfile to get pid"}
        pid=$(cat "$pidfile")
    elif [ "$pidPattern" = "--cmdpattern" ]; then
        cmdpattern=${6?"command line pattern to find out pid"}
        pid=$(pidof "$cmdpattern")
    elif [ "$pidPattern" = "--pid" ]; then
        pid=${6?"pid"}
    else
        echo "ERROR input for pidpattern"
        exit 2
    fi

    if [ -z "$pid" ]; then
        echo "ERROR: no related process is found"
        exit 2
    fi

    memTotal=$(free --mega | grep -oP '\d+' | head -n 1)
    memWarn=$((memTotal*$2/100))
    memCrit=$((memTotal*$4/100))

    memVmSize=$(grep 'VmSize:' "/proc/${pid}/status" | awk -F' ' '{print $2}')
    memVmSize=$((memVmSize/1024))

    memVmRSS=$(grep 'VmRSS:' "/proc/${pid}/status" | awk -F' ' '{print $2}')
    memVmRSS=$((memVmRSS/1024))

    if [ "$memVmRSS" -ge "$memCrit" ]; then
        echo "Memory: CRITICAL RES: $memVmRSS MB - VIRT: $memVmSize MB used!|RES=$((memVmRSS))MB;$((memWarn));$((memCrit));0;$((memTotal)) VIRT=$((memVmSize))MB;$((memWarn));$((memCrit));0;$((memTotal))"
        exit 2
    elif [ "$memVmRSS" -ge "$memWarn" ]; then
        echo "Memory: WARNING RES: $memVmRSS MB - VIRT: $memVmSize MB used!|RES=$((memVmRSS))MB;$((memWarn));$((memCrit));0;$((memTotal)) VIRT=$((memVmSize))MB;$((memWarn));$((memCrit));0;$((memTotal))"
        exit 1
    else
        echo "Memory: OK RES: $memVmRSS MB - VIRT: $memVmSize MB used|RES=$((memVmRSS))MB;$((memWarn));$((memCrit));0;$((memTotal)) VIRT=$((memVmSize))MB;$((memWarn));$((memCrit));0;$((memTotal))"
        exit 0
    fi

else
    echo "check_proc_mem v1.0 (modified)"
    echo ""
    echo "Usage:"
    echo "check_proc_mem.sh -w <warn_MB> -c <criti_MB> <pid_pattern> <pattern_argument>"
    echo ""
    echo "Below: If tomcat use more than 1024MB resident memory, send warning"
    echo "check_proc_mem.sh -w 1024 -c 2048 --pidfile /var/run/tomcat7.pid"
    echo "check_proc_mem.sh -w 1024 -c 2048 --pid 11325"
    echo "check_proc_mem.sh -w 1024 -c 2048 --cmdpattern \"tomcat7.*java.*Dcom\""
    echo ""
    echo "Copyright (C) 2014 DennyZhang (contact@dennyzhang.com)"
    echo "Called as: $@"
    exit
fi
## File - check_proc_mem.sh ends
