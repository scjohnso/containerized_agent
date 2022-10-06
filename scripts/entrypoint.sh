#! /bin/bash
set -m
{ ./agent_start.sh ; } & { sleep 60; until login-agent.sh $USERNAME $PASSWORD ; do sleep 10; done ; }
fg