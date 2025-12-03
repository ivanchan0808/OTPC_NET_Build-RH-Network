#!/bin/bash
SERVER=`hostname`
VAR_1="/root/otpc_net_${SERVER}/new_config/"
PROFILE="BB"
_CMD_1="change-profile.sh"
_CMD_2="ping-test.sh"
_CMD_3="check-all-ping-latency.sh"
RHEL8_PATH="/home/ps_syssupp/OTPC_NET_Build-RH-Network/"
RHEL7_PATH="/home/syssupp/OTPC_NET_Build-RH-Network/"
RHEL8_OUTPUT_FILE="/home/ps_syssupp/otpc_log_${SERVER}/remote_bg_call.out"
RHEL7_OUTPUT_FILE="/home/syssupp/otpc_log_${SERVER}/remote_bg_call.out"

if [[ -d "$RHEL8_PATH" ]]; then
    nohup bash "${RHEL8_PATH}${_CMD_1}" $VAR_1 $PROFILE > $RHEL8_OUTPUT_FILE 2>&1 &
    job_pid=$!
    wait $job_pid
    echo "Sleep 10mins and then restart Now! "
    sleep 600; restart

elif [[ -d "$RHEL7_PATH" ]]; then
    nohup bash "${RHEL7_PATH}${_CMD_1}" $VAR_1 $PROFILE > $RHEL7_OUTPUT_FILE 2>&1 &
    job_pid=$!
    wait $job_pid
    echo "Sleep 10mins and then restart Now! "
    sleep 600; restart

fi
