#!/bin/bash

ORION_URL=$1

curl -iX POST \
  "$ORION_URL/v2/subscriptions" \
  -H 'Content-Type: application/json' \
  -d '{
  "description": "Notify Cygnus of all context changes.",
  "subject": {
    "entities": [
      {
        "idPattern": ".*"
      }
    ]
  },
  "notification": {
    "http": {
      "url": "http://cygnus:5052/notify"
    },
    "attrsFormat": "legacy"
  },
  "throttling": 5
}'
