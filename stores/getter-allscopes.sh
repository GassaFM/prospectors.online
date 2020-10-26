#!/bin/bash
export DFUSETOKEN=`cat ../dfuse.token`
curl -X POST \
     -H "Authorization: Bearer $DFUSETOKEN" \
     -d "account=prospectorsc&table=$1&scopes=`./scopelist_piper < $1.scopelist.json`&json=false&key_type=$2" \
     --compressed \
     "https://eos.dfuse.eosnation.io/v0/state/tables/scopes" \
     > $1.allscopes.binary
