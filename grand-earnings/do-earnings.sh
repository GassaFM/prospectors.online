#!/bin/bash
cd "${0%/*}"
rm -f *.json || exit 1
../earnings/refresh-logs-ng "https://wax.dfuse.eosnation.io/graphql" \
    "account:prospectorsn action:withdraw" \
    "account:prospectorsw action:transfer data.to:prospectorsn" || exit 1
../earnings/earnings-all prospectorsn "https://wax.dfuse.eosnation.io/v0/block_id/by_time" \
    "https://wax.dfuse.eosnation.io/v0/state/table" \
    "account:prospectorsn action:withdraw" \
    "account:prospectorsw action:transfer data.to:prospectorsn" \
    || exit 1
mv *.html ../public_html/grand/earnings/ || exit 1
rm -f *.json || exit 1
