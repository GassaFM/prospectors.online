#!/bin/bash
export DFUSETOKEN=`cat ../dfuse.token`
curl --get \
     -H "Authorization: Bearer $DFUSETOKEN" \
     --data-urlencode "account=prospectorsc" \
     --data-urlencode "scope=prospectorsc" \
     --data-urlencode "table=$1" \
     --data-urlencode "key_type=$2" \
     --data-urlencode "json=false" \
     --compressed \
     "https://mainnet.wax.dfuse.io/v0/state/table" \
     > $1.binary
