#!/bin/bash
export DFUSETOKEN=`cat ../dfuse.token`
curl --get \
     -k \
     -H "Authorization: Bearer $DFUSETOKEN" \
     --data-urlencode "account=prospectorsn" \
     --data-urlencode "table=$1" \
     --data-urlencode "key_type=name" \
     --compressed \
     "https://wax.dfuse.eosnation.io/v0/state/table_scopes" \
     > $1.scopelist.json
