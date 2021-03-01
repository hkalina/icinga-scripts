#!/bin/bash

echo "`date` Debug: $@" >> /var/log/icinga_restart.log

while getopts "s:t:a:S:" opt; do
  case $opt in
    s)
      servicestate=$OPTARG
      ;;
    t)
      servicestatetype=$OPTARG
      ;;
    a)
      serviceattempt=$OPTARG
      ;;
    S)
      service=$OPTARG
      ;;
  esac
done

if ( [ -z $servicestate ] || [ -z $servicestatetype ] || [ -z $serviceattempt ] || [ -z $service ] ); then
  echo "USAGE: $0 -s servicestate -z servicestatetype -a serviceattempt -S service"
  exit 3;
else
  # Only restart on the third attempt of a critical event
  if ( [ $servicestate == "CRITICAL" ] && [ $servicestatetype == "SOFT" ] && [ $serviceattempt -eq 3 ] ); then
    echo "`date` RESTART $service - state critical" >> /var/log/icinga_restart.log
    sudo /usr/bin/systemctl restart $service
  fi
fi
