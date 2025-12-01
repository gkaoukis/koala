#!/bin/sh
# https://github.com/iiiiiii1/Block-IPs-from-countries/blob/master/block-ips.sh
# Block IPs from countries
# Assumes Debian-based system with ipset installed

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root!" >&2
    exit 1
fi

# Block IPs
block_ipset() {
    if [ ! -f "$1" ]; then
        echo "Error: Input file not found: $1" >&2
        exit 1
    fi
    
    printf "Enter country code to block (e.g., cn): "
    read -r GEOIP
    
    # Create ipset rule
    ipset -N "$GEOIP" hash:net 2>/dev/null || {
        echo "Error: Failed to create ipset. May already exist." >&2
        exit 1
    }
    
    # Add IPs from file
    while IFS= read -r ip; do
        ipset -A "$GEOIP" "$ip"
    done < "$1"
    
    echo "Rules added successfully, blocking IPs..."
    
    # Block traffic
    iptables -I INPUT -p tcp -m set --match-set "$GEOIP" src -j DROP
    iptables -I INPUT -p udp -m set --match-set "$GEOIP" src -j DROP
    
    echo "Country ($GEOIP) IPs blocked successfully!"
}

# Unblock IPs
unblock_ipset() {
    printf "Enter country code to unblock (e.g., cn): "
    read -r GEOIP
    
    # Check if rule exists
    if ipset list | grep -q "Name: $GEOIP"; then
        iptables -D INPUT -p tcp -m set --match-set "$GEOIP" src -j DROP
        iptables -D INPUT -p udp -m set --match-set "$GEOIP" src -j DROP
        ipset destroy "$GEOIP"
        echo "Country ($GEOIP) IPs unblocked and rules deleted!"
    else
        echo "Error: No rules found for country: $GEOIP" >&2
        exit 1
    fi
}

# Show block list
block_list() {
    iptables -L | grep match-set
}

# Main menu
main() {
    if [ -z "$1" ]; then
        echo "Usage: $0 <ip_list_file>" >&2
        exit 1
    fi
    
    clear
    echo "-------------------------------------------"
    echo "Block IPs by country"
    echo "1. Block IPs"
    echo "2. Unblock IPs"
    echo "3. Show block list"
    echo "-------------------------------------------"
    printf "Enter choice [1-3]: "
    read -r num
    
    case "$num" in
        1) block_ipset "$1" ;;
        2) unblock_ipset ;;
        3) block_list ;;
        *)
            clear
            echo "Invalid choice [1-3]"
            sleep 2
            main "$1"
            ;;
    esac
}

main "$1"