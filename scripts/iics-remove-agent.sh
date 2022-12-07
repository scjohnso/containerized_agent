echo "Removing hostname: $1"

### Login and get agent ID
SESSION_ID=$(curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{\"username\":\"${2}\",\"password\":\"${3}\"}" https://${LOGIN_DOMAIN}.informaticacloud.com/saas/public/core/v3/login | jq -r '.userInfo.sessionId')
AGENT_ID=$(curl -H "icSessionid: $SESSION_ID" https://na1.dm-us.informaticacloud.com/saas/api/v2/agent/name/${1} | jq -r '.id')

### Try to limit the amount of delete commands issued immediately
RAND=`shuf -i 1-11 -n 1`; sleep $RAND

curl -X DELETE -H "icSessionid: $SESSION_ID" https://na1.dm-us.informaticacloud.com/saas/api/v2/agent/${AGENT_ID}

echo "Secure agent has tried to be deleted. If only one agent remains, it can't be deleted"