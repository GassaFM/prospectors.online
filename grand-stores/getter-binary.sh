#!/bin/bash
export DFUSETOKEN=`cat ../dfuse.token`
curl --get \
     -H "Authorization: Bearer $DFUSETOKEN" \
     --data-urlencode "account=prospectorsn" \
     --data-urlencode "scope=prospectorsn" \
     --data-urlencode "table=$1" \
     --data-urlencode "key_type=$2" \
     --data-urlencode "json=false" \
     --compressed \
     "https://wax.dfuse.eosnation.io/v0/state/table" \
     > $1.binary
