#!/bin/bash
export DFUSETOKEN=`cat ../dfuse.token`
curl --get \
     -k \
     -H "Authorization: Bearer $DFUSETOKEN" \
     --data-urlencode "account=prospectorsc" \
     --data-urlencode "table=$1" \
     --data-urlencode "scopes=`../stores/scopelist_piper < $1.scopelist.json`" \
     --data-urlencode "json=false" \
     --data-urlencode "key_type=$2" \
     --compressed \
     "https://mainnet.wax.dfuse.io/v0/state/tables/scopes" \
     > $1.allscopes.binary