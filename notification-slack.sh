#!/bin/bash

SERVICE="$1"
HOST="$2"
STATE="$3"
SLACKURL="$4" # see https://api.slack.com/messaging/webhooks
OUTPUT="$5"

curl -X POST \
    -H 'Content-type: application/json' \
    --data "{\"text\":\"${SERVICE} at ${HOST} is ${STATE}: ${OUTPUT}\"}" \
    "$SLACKURL"

echo "Sent"

