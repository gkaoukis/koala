#!/bin/sh
# portcheck.sh
# adapted from https://github.com/opencord/automation-tools/blob/master/scripts/portcheck.sh

if [ -z "$1" ]; then
    echo "Usage: $0 <port-file>"
    exit 2
fi

portfile=$1

number_of_ports_in_use=0
reserved=""

# Read file line-by-line. Skip empty lines and lines beginning with '#'.
while IFS= read -r port || [ -n "$port" ]; do
    # Trim leading/trailing whitespace (portable approach)
    # remove leading spaces/tabs
    port="${port#"${port%%[! 	]*}"}"
    # remove trailing spaces/tabs
    port="${port%"${port##*[! 	]}"}"

    [ -z "$port" ] && continue
    case $port in
        \#*) continue ;;  # skip comment lines
    esac

    # Check listening processes for the port
    if netstat -lntp 2>/dev/null | grep -F ":$port" >/dev/null 2>&1; then
        used_process=$(netstat -lntp 2>/dev/null | grep -F ":$port" | tr -s ' ' | cut -f7 -d' ' | head -n 1)
        echo "ERROR: Process with PID/Program_name $used_process is already listening on port: $port needed by SEBA"
        number_of_ports_in_use=$((number_of_ports_in_use + 1))
    fi

    # accumulate reserved ports as CSV
    reserved="${reserved}${port},"
done < "$portfile"

# If any ports are in use, notify and exit
if [ "$number_of_ports_in_use" -gt 0 ]; then
    echo "Kill the running services mentioned above before proceeding to install SEBA"
    echo "Terminating make"
    exit 1
fi

# strip trailing comma
reserved=${reserved%%,}

# Write reserved ports to kernel setting
echo "$reserved" > /proc/sys/net/ipv4/ip_local_reserved_ports 2>/dev/null || {
    echo "ERROR: Failed to write to /proc/sys/net/ipv4/ip_local_reserved_ports (permission denied?)"
    exit 1
}

echo "SUCCESS: Added ports required for SEBA services to ip_local_reserved_ports"
exit 0
