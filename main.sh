#!/usr/bin/env bash
#
# zone_transfer_test.sh - Interactive DNS zone transfer test (CVE-1999-0532)
#
# This script prompts for domain(s) or a file, then attempts AXFR against
# the authoritative name servers. Only use on domains you own or have
# explicit permission to test.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check for required tools
if ! command -v dig &> /dev/null; then
    echo -e "${RED}Error: 'dig' is required but not installed.${NC}"
    echo "Install it with: sudo apt install dnsutils (Debian/Ubuntu) or sudo yum install bind-utils (RHEL/CentOS)"
    exit 1
fi

# Function to test a single domain
test_domain() {
    local domain="$1"
    echo -e "\n${YELLOW}=== Testing domain: $domain ===${NC}"

    # Get name servers for the domain
    local nameservers
    nameservers=$(dig +short NS "$domain" | grep -v '^;' | sort -u)
    if [[ -z "$nameservers" ]]; then
        echo -e "${RED}No NS records found for $domain. Skipping.${NC}"
        return 1
    fi

    echo "Name servers:"
    echo "$nameservers" | sed 's/^/  /'

    local any_success=false
    while read -r ns; do
        # Remove trailing dot if present
        ns="${ns%.}"
        echo -e "\n${YELLOW}Attempting zone transfer from $ns...${NC}"
        
        # Perform AXFR query (use TCP)
        if dig +tcp @"$ns" "$domain" AXFR +short +time=5 +tries=1 2>/dev/null | grep -v '^;' | grep -q .; then
            echo -e "${GREEN}SUCCESS: Zone transfer allowed from $ns${NC}"
            echo "Zone data:"
            dig +tcp @"$ns" "$domain" AXFR +short 2>/dev/null | sed 's/^/    /'
            any_success=true
        else
            echo -e "${RED}FAILED: Zone transfer refused or not allowed from $ns${NC}"
        fi
    done <<< "$nameservers"

    if [[ "$any_success" == false ]]; then
        echo -e "\n${GREEN}No zone transfer vulnerability found for $domain.${NC}"
    else
        echo -e "\n${RED}WARNING: $domain is vulnerable to zone transfers!${NC}"
    fi
}

# Interactive prompt
echo -e "${YELLOW}DNS Zone Transfer Test (CVE-1999-0532)${NC}"
echo "This script attempts to retrieve full DNS records from the authoritative name servers."
echo "Only use on domains you own or have explicit permission to test."
echo

read -p "Enter target domain(s) (space-separated) or 'file:<filename>': " input

# Trim leading/trailing spaces
input="$(echo -e "$input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if [[ -z "$input" ]]; then
    echo -e "${RED}No input provided. Exiting.${NC}"
    exit 1
fi

# Check if input is a file reference
if [[ "$input" =~ ^file: ]]; then
    filename="${input#file:}"
    if [[ ! -f "$filename" ]]; then
        echo -e "${RED}File '$filename' not found. Exiting.${NC}"
        exit 1
    fi
    echo "Reading domains from $filename ..."
    while IFS= read -r domain || [[ -n "$domain" ]]; do
        # Skip empty lines and comments
        [[ -z "$domain" || "$domain" =~ ^[[:space:]]*# ]] && continue
        test_domain "$domain"
    done < "$filename"
else
    # Treat as space-separated domains
    for domain in $input; do
        test_domain "$domain"
    done
fi

echo -e "\n${YELLOW}Testing completed.${NC}"
