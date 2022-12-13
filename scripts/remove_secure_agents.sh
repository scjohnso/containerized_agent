#! /bin/bash

### This script removes any secure agents for the RUNTIME Environment that may have been caused by crashes / ungraceful shutdown

username=$1
password=$2

### Ensure that your runtime name matches where you want to delete from
RUNTIME_NAME=${RUNTIME_NAME}

### Login
SESSION_ID=$(curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{\"username\":\"${username}\",\"password\":\"${password}\"}" https://${LOGIN_DOMAIN}.informaticacloud.com/saas/public/core/v3/login | jq -r '.userInfo.sessionId')
CONFIG_URL=$(curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{\"username\":\"${username}\",\"password\":\"${password}\"}" https://${LOGIN_DOMAIN}.informaticacloud.com/saas/public/core/v3/login | jq -r '.products[0].baseApiUrl')

### Get the ID of the runtime
RUNTIME_ID=$(curl -H "Content-Type: application/json" -H "Accept: application/json" -H "icSessionid: $SESSION_ID" ${CONFIG_URL}/api/v2/runtimeEnvironment/name/${RUNTIME_NAME} | jq -r '.id' )

### Get the list of agents in org
AGENT_JSON=$(curl -H "Content-Type: application/json" -H "Accept: application/json" -H "icSessionid: $SESSION_ID" ${CONFIG_URL}/api/v2/agent)

### Filter out inactive agents that match the runtime group
JSON_LIST=$(echo "${AGENT_JSON}" | jq --arg RUNTIME_ID "$RUNTIME_ID" -c '.[] | select(.agentGroupId==$RUNTIME_ID) | select(.active==false) | select(.readyToRun==false)')

### Actually remove the agents in a loop
for json in $JSON_LIST; do AGENT_ID=$(echo $json | jq -r '.id'); echo "Removing ${AGENT_ID}"; curl -X DELETE -H "icSessionid: $SESSION_ID" ${CONFIG_URL}/api/v2/agent/${AGENT_ID}; done