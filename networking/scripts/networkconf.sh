#!/bin/sh
# source: https://bash.cyberciti.biz/networking/shell-script-to-find-linux-network-configurations/
HWINF=/usr/sbin/hwinfo
IFCFG=/sbin/ifconfig
IP4FW=/sbin/iptables
IP6FW=/sbin/ip6tables
LSPCI=/usr/bin/lspci
ROUTE=/sbin/route
NETSTAT=/bin/netstat
LSB=/usr/bin/lsb_release
IP=/sbin/ip

DNSCLIENT="/etc/resolv.conf"
DRVCONF="/etc/modprobe.d"
NETCFC="/etc/network/interfaces"
SYSCTL="/etc/sysctl.conf"

## Output file ##
OUTPUT="network.$(date +'%d-%m-%y').info.txt"

chk_root(){
	meid=$(id -u)
	if [ "$meid" -ne 0 ]; then
		echo "You must be root user to run this tool"
		exit 999
	fi
}

write_header(){
	echo "---------------------------------------------------" >> "$OUTPUT"
	echo "$@" >> "$OUTPUT"
	echo "---------------------------------------------------" >> "$OUTPUT"
}

dump_info(){
	echo "* Hostname: $(hostname)" > "$OUTPUT"
	echo "* Run date and time: $(date)" >> "$OUTPUT"

	write_header "Linux Distro"
	echo "Linux kernel: $(uname -mrs)" >> "$OUTPUT"
	if [ -x "$LSB" ]; then
		$LSB -a >> "$OUTPUT"
	fi

	if [ -x "$HWINF" ]; then
		write_header "$HWINF --network_ctrl"
		$HWINF --network_ctrl >> "$OUTPUT"
	fi

	if [ -x "$HWINF" ]; then
		write_header "$HWINF --isapnp"
		$HWINF --isapnp >> "$OUTPUT"
	fi

	write_header "PCI Devices"
	if [ -x "$LSPCI" ]; then
		$LSPCI -v >> "$OUTPUT"
	fi

	write_header "Network Interfaces (ifconfig)"
	if [ -x "$IFCFG" ]; then
		$IFCFG >> "$OUTPUT"
	fi

	write_header "Network Interfaces (ip addr)"
	if [ -x "$IP" ]; then
		$IP addr show >> "$OUTPUT"
	fi

	write_header "Kernel Routing Table (route)"
	if [ -x "$ROUTE" ]; then
		$ROUTE -n >> "$OUTPUT"
	fi

	write_header "Kernel Routing Table (ip route)"
	if [ -x "$IP" ]; then
		$IP route show >> "$OUTPUT"
	fi

	write_header "Network Module Configuration $DRVCONF"
	if [ -d "$DRVCONF" ]; then
		find "$DRVCONF" -type f -exec grep -l eth {} \; -exec echo "** {} **" \; -exec cat {} \; >> "$OUTPUT"
	else
		echo "Error $DRVCONF directory not found." >> "$OUTPUT"
	fi

	write_header "DNS Client $DNSCLIENT Configuration"
	if [ -f "$DNSCLIENT" ]; then
		cat "$DNSCLIENT" >> "$OUTPUT"
	else
		echo "Error $DNSCLIENT file not found." >> "$OUTPUT"
	fi

	write_header "Network Configuration File"
	if [ -f "$NETCFC" ]; then
		echo "** $NETCFC **" >> "$OUTPUT"
		cat "$NETCFC" >> "$OUTPUT"
	else
		echo "Error $NETCFC not found." >> "$OUTPUT"
	fi

	write_header "IP4 Firewall Configuration"
	if [ -x "$IP4FW" ]; then
		$IP4FW -L -n >> "$OUTPUT"
	fi

	write_header "IP6 Firewall Configuration"
	if [ -x "$IP6FW" ]; then
		$IP6FW -L -n >> "$OUTPUT"
	fi

	write_header "Network Stats"
	if [ -x "$NETSTAT" ]; then
		$NETSTAT -s >> "$OUTPUT"
	fi

	write_header "Network Tweaks via $SYSCTL"
	if [ -f "$SYSCTL" ]; then
		cat "$SYSCTL" >> "$OUTPUT"
	else
		echo "Error $SYSCTL not found." >> "$OUTPUT"
	fi
}

chk_root
dump_info