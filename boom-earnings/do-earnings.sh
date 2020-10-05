#!/bin/bash
cd "${0%/*}"
rm -f *.json || exit 1
../earnings/refresh-logs "https://mainnet.eos.dfuse.io/v0/search/transactions" \
    "account:prospectorsq action:withdraw" \
    "account:prospectorsg action:transfer data.to:prospectorsq" || exit 1
../earnings/earnings-all prospectorsq "https://mainnet.eos.dfuse.io/v0/block_id/by_time" \
    "https://mainnet.eos.dfuse.io/v0/state/table" \
    "account:prospectorsq action:withdraw" \
    "account:prospectorsg action:transfer data.to:prospectorsq" \
    || exit 1
mv *.html ../public_html/boom/earnings/ || exit 1
rm -f *.json || exit 1
