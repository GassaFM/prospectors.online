#!/bin/bash
cd "${0%/*}"
rm -f *.json || exit 1
../earnings/refresh-logs-ng "https://wax.dfuse.eosnation.io/graphql" \
    "account:prospectorsq action:withdraw" \
    "account:prospectorsw action:transfer data.to:prospectorsq" || exit 1
../earnings/earnings-all prospectorsq "https://wax.dfuse.eosnation.io/v0/block_id/by_time" \
    "https://wax.dfuse.eosnation.io/v0/state/table" \
    "account:prospectorsq action:withdraw" \
    "account:prospectorsw action:transfer data.to:prospectorsq" \
    || exit 1
mv *.html ../public_html/eagle/earnings/ || exit 1
rm -f *.json || exit 1
