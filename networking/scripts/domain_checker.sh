#!/bin/sh
# https://github.com/IvanGlinkin/Domain_checker/blob/main/domain_checker.sh
RED='\033[0;31m'
RED_BOLD='\033[1;31m'
GREEN='\033[0;32m'
GREEN_BOLD='\033[1;32m'
ORANGE='\033[0;33m'
BLUE='\033[1;36m'
CLEAR_FONT='\033[0m'

is_valid_domain() {
    echo "$1" | grep -Eq '^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$'
    if [ $? -ne 0 ]; then
        printf "%b[ - ]%b Error:%b %s%b is not a proper domain name\n" "$RED_BOLD" "$CLEAR_FONT" "$RED_BOLD" "$1" "$CLEAR_FONT"
        exit 1
    fi
}

printf "[ < ] Enter the domain name: "
read domain

is_valid_domain "$domain"

ip=$(host "$domain" | awk '/has address/ { print $4 }' | head -n 1)

if [ -z "$ip" ] ; then
    printf "%b[ - ]%b Error: Domain%b %s%b does not exist\n" "$RED_BOLD" "$CLEAR_FONT" "$RED_BOLD" "$domain" "$CLEAR_FONT"
    exit 1
fi

printf "%b[ + ]%b Domain name%b %s%b exists. Start enumerating...\n\n" "$GREEN_BOLD" "$CLEAR_FONT" "$GREEN_BOLD" "$domain" "$CLEAR_FONT"
printf "%b[ + ]%b IP address is%b %s%b\n" "$GREEN_BOLD" "$CLEAR_FONT" "$GREEN_BOLD" "$ip" "$CLEAR_FONT"
printf "%b[ > ]%b Checking for subdomains...\n" "$BLUE" "$CLEAR_FONT"

all_ips="$ip"
clean_subdomains=""

raw_subdomains=$(curl -s "http://web.archive.org/cdx/search/cdx?url=*.$domain/*&output=json&fl=original&collapse=urlkey" | awk -F ":" '{print $2}' | cut -d "/" -f 3 | cut -d "\"" -f 1 | uniq | sort -u | grep -v -e '^$')

for subdomain in $raw_subdomains; do
    case "$subdomain" in
        "$domain"|www*."$domain") continue ;;
    esac

    current_ip=$(host "$subdomain" | awk '/has address/ { print $4 }' | head -n 1)
    
    if [ -n "$current_ip" ]; then
        printf "\t%b[ + ]%b %s | %s\n" "$GREEN_BOLD" "$CLEAR_FONT" "$subdomain" "$current_ip"
        all_ips="$all_ips $current_ip"
        clean_subdomains="$clean_subdomains $subdomain"
    fi
done

if [ -z "$clean_subdomains" ] ; then
    printf "\t%b[ - ]%b Subdomains do not exist\n" "$RED_BOLD" "$CLEAR_FONT"
fi

printf "%b[ ! ]%b Cleaning up IP addresses...\n" "$ORANGE" "$CLEAR_FONT"
sorted_ips=$(echo "$all_ips" | tr ' ' '\n' | sort -u | grep -v '^$')
printf "%b[ > ]%b Checking for Top 100 ports and output results...\n" "$BLUE" "$CLEAR_FONT"

for target_ip in $sorted_ips; do
    ports=$(nmap --top-ports 100 "$target_ip" | grep '^[0-9]' | awk '{ print $1 }' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    country=$(geoiplookup "$target_ip" | cut -d ":" -f 2 | sed 's/^ //')
    printf "\t%b[ + ]%b %s | %s | %s\n" "$GREEN_BOLD" "$CLEAR_FONT" "$target_ip" "$country" "$ports"
done