#!/bin/bash

ipc="/var/opera/opera/opera.ipc"

# requires following in visudo:
# nagios ALL = (opera) NOPASSWD: /usr/bin/chmod g+r+w /var/opera/opera/opera.ipc

req='{"jsonrpc":"2.0","method":"net_version","params":[],"id":123}'
expected='{"jsonrpc":"2.0","id":123,"result":"250"}'
warn=$1 # in seconds as 0.12
crit=$2 # in seconds as 1.12

if [ ! -e "$ipc" ]; then
    echo "IPC file $ipc does not exists!"
    exit 2 # critical
fi

if [ ! -w "$ipc" ]; then
   sudo -u opera chmod g+r+w $ipc
fi

if [ ! -w "$ipc" ]; then
    echo "IPC file $ipc not writable by `whoami`/`groups`!"
    exit 3 # unknown
fi

echo "$req" | /usr/bin/time -f %e nc -N -U "$ipc" 2>&1 | {
    read output
    read eclapsed
    perf="time=${eclapsed}s;$warn;$crit;0;"
    if [ "$output" == "$expected" ]; then
        if [ $(echo "${eclapsed}>$crit"|bc) == 1 ]; then
            echo "Response VERY late but correct - in $eclapsed seconds|$perf";
            echo "$output"
            exit 2 # critical
        elif [ $(echo "${eclapsed}>$warn"|bc) == 1 ]; then
            echo "Response too late but correct - in $eclapsed seconds|$perf"
            echo "$output"
            exit 1 # warning
        else
            echo "Response OK in $eclapsed seconds|$perf"
            echo "$output"
            exit 0 # OK
        fi
    else
        echo "Wrong response: $output|$perf"
        exit 2 # critical
    fi
}
