#!/bin/bash


##### New add on 03-Sep-2025 (Select VLAN INTERFACE)
NM_CONFIG_FILTER="/etc/NetworkManager/system-connections/*.*.nmconnection"
NS_CONFIG_FILTER="/etc/sysconfig/network-scripts/ifcfg-*.*"
CONFIG_FILTER=""

##### New add on 24-Jul-2025
VERSION=`awk '{print $6}' /etc/redhat-release`
if [[ $VERSION == "release" ]]; then
    VERSION=`awk '{print $7}' /etc/redhat-release`
fi

if (( $(echo "$VERSION >= 8" | bc -l) )); then
    USER="ps_syssupp"
    if (( $(echo "$VERSION >= 9" | bc -l) )); then 
        CONFIG_FILTER=$NM_CONFIG_FILTER
    else 
        CONFIG_FILTER=$NS_CONFIG_FILTER
    fi
elif (( $(echo "$VERSION >= 7" | bc -l) )); then
    USER="syssupp"
    CONFIG_FILTER=$NS_CONFIG_FILTER
fi

SERVER=`hostname`
FIRST_CHAR=$(echo "$SERVER" | cut -c1)
CSV_FILE="/home/${USER}/OTPC_NET_Build-RH-Network/${FIRST_CHAR}_gw.csv"

LOG_PATH="/home/${USER}/otpc_log_${SERVER}/"

if [ ! -d "/home/${USER}" ]; then
    LOG_PATH="/tmp/otpc_log_${SERVER}/"
    echo "${USER} is not exit!"
    echo " LOG PATH change to ${LOG_PATH}!"
    USER=`whoami`
fi  

if [ ! -d "$LOG_PATH" ]; then
    echo "Creating log folder - $LOG_PATH"
    mkdir -p $LOG_PATH
fi

LOG_DEBUG_FILE="${LOG_PATH}set-baseline.running.log"
echo "========================Start running script $(date)========================" | tee -a $LOG_DEBUG_FILE
#####

GATEWAY_FILE="${LOG_PATH}/gateway_ips.txt"
# Create/clear gateway IP file
> "$GATEWAY_FILE"

# Function: Extract gateway IPs and save to file
extract_gateway_ips() {
#    ip route | awk '
#        ($1 == "default" && $2 == "via") { print $3 }
#        ($2 == "via") { print $3 }
#    ' | sort -u > "$GATEWAY_FILE"
    SEDMAINFIL='s/.*via\ \([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)\ dev \(.*\)\(\ proto.*\|\)$/\1/p'
    MAINRGW=$( ip route list | grep -v 'scope link' | sort | sed -n -e "${SEDMAINFIL}" | sort -u )
    echo -e "${MAINRGW}" > "$GATEWAY_FILE"
}

ping_gateways() {
    echo "=== Ping Test: $(date) ===" >> "$1"
    while read -r ip; do
        if [[ -n "$ip" ]]; then
            echo "Pinging $ip ..." | tee -a "$1"
            ping -c 4 -W 1 "$ip" >> "$1" 2>&1
            echo "---" >> "$1"
        fi
    done < "$GATEWAY_FILE"
}

extract_vlan_gateways() {
# Check if CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file $CSV_FILE not found!"
    exit 1
fi

# Process each bond connection file
    ls $CONFIG_FILTER | while read filename; do
    # Extract VLAN number from filename
    vlan=$(echo "$filename" | awk -F'.' '{print $2}')
    
    # Look up IP address in CSV file
    ip_address=$(awk -F',' -v vlan="$vlan" '$1 == vlan {print $2}' "$CSV_FILE")
    
    if [[ -n "$ip_address" ]]; then
        echo "VLAN: $vlan -> IP: $ip_address" |tee -a $LOG_DEBUG_FILE
        echo $ip_address >> $GATEWAY_FILE |tee -a $LOG_DEBUG_FILE
    else
        echo "VLAN: $vlan -> No IP found in CSV" |tee -a $LOG_DEBUG_FILE
    fi
done
}

echo " Extract ip route gateway........ " |tee -a $LOG_DEBUG_FILE
extract_gateway_ips |tee -a $LOG_DEBUG_FILE

echo "Create ping baseline............. " |tee -a $LOG_DEBUG_FILE
ping_gateways "${LOG_PATH}/original_ping.log" |tee -a $LOG_DEBUG_FILE

echo "Create IP Route baseline" |tee -a $LOG_DEBUG_FILE
ip route | tee "${LOG_PATH}/original_route.log" |tee -a $LOG_DEBUG_FILE

echo "Extract VLAN GATEWAY............. " |tee -a $LOG_DEBUG_FILE
extract_vlan_gateways
echo "==============================Exit script $(date)===============================" | tee -a $LOG_DEBUG_FILE