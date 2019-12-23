#!/bin/bash
cd "${0%/*}"
./refresh_log_buys "https://mainnet.wax.dfuse.io/graphql" | tee -a buys-log.txt || exit 1
./refresh_log_sales "https://mainnet.wax.dfuse.io/graphql" | tee -a sales-log.txt || exit 1
./display_deals || exit 1
mv *.html ../public_html/wax/trades/ || exit 1
