#!/bin/bash

# Retrieve and format HAProxy statistics.
# Usage: haproxy-stats.sh [view] [backend_name]
# View options: basic, health, performance, errors, connections, full

set -euo pipefail

VIEW=${1:-basic}
BACKEND=${2:-}

SOCK="/run/haproxy/admin.sock"

# Get raw stats from HAProxy
RAW=$(echo "show stat" | sudo socat stdio "$SOCK")

# Split header into an array
HEADER=$(echo "$RAW" | head -n1)
HEADER=${HEADER#\#}
IFS=',' read -ra HCOLS <<< "$HEADER"

# Helper to get column numbers for a comma separated list of names
index_for() {
    local list=$1
    local idx=()
    for name in ${list//,/ }; do
        for i in "${!HCOLS[@]}"; do
            if [[ "${HCOLS[$i]}" == "$name" ]]; then
                idx+=("$((i+1))")
                break
            fi
        done
    done
    echo "$(IFS=','; echo "${idx[*]}")"
}

case "$VIEW" in
    basic)
        FIELDS="pxname,svname,status,scur,smax,slim,stot,bin,bout";;
    health)
        FIELDS="pxname,svname,status,chkfail,chkdown,lastchg,downtime,check_status,check_code,check_duration,last_chk,check_desc,check_rise,check_fall,check_health";;
    performance)
        FIELDS="pxname,svname,rate,rate_max,req_rate,req_rate_max,req_tot,hrsp_1xx,hrsp_2xx,hrsp_3xx,hrsp_4xx,hrsp_5xx";;
    errors)
        FIELDS="pxname,svname,ereq,econ,eresp,wretr,wredis,cli_abrt,srv_abrt";;
    connections)
        FIELDS="pxname,svname,conn_rate,conn_rate_max,conn_tot,intercepted,dcon,dses";;
    full)
        FIELDS="$HEADER";;
    *)
        echo "Unknown view '$VIEW'" >&2
        exit 1;;
esac

IDX=$(index_for "$FIELDS")

# Print header
echo "$FIELDS" | tr ' ' ','

# Print data lines filtered by backend and selected fields
DATA=$(echo "$RAW" | tail -n +2)

echo "$DATA" | awk -F',' -v idxs="$IDX" -v backend="$BACKEND" '
BEGIN{split(idxs,id,",")}
{
    if(backend=="" || $1==backend){
        out="";
        for(i=1;i<=length(id);i++){
            if(out!="") out=out ",";
            out=out $(id[i]);
        }
        print out;
    }
}
'
