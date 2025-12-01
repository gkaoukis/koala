#!/bin/bash
# https://github.com/CYBWithFlourish/IP-Sweeper-Script/blob/main/ip_sweeper.sh
SUBNET="192.168.1"

echo "Pinging subnet $SUBNET.0/24..."


for ip in {1..254}; do
    if ping -c 1 -W 1 $SUBNET.$ip > /dev/null; then
        echo "Host $SUBNET.$ip is UP"
    fi
done