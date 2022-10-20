echo "Removing hostname: $1"

SESSION_ID=$(curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{\"username\":\"${username}\",\"password\":\"${password}\"}" https://${LOGIN_DOMAIN}.informaticacloud.com/saas/public/core/v3/login | jq -r '.userInfo.sessionId')

AGENT_ID=$(curl -H "icSessionid: $SESSION_ID" https://na1.dm-us.informaticacloud.com/saas/api/v2/agent/name/${1} | jq -r '.id')
curl -X DELETE -H "icSessionid: $SESSION_ID" https://na1.dm-us.informaticacloud.com/saas/api/v2/agent/${AGENT_ID}
