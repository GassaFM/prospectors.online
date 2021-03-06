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
     "https://eos.dfuse.eosnation.io/v0/state/table" \
     > $1.binary
#     --data-urlencode "block_num=154999999" \
