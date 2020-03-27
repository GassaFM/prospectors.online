#!/bin/bash
cd "${0%/*}"
./refresh_log_banks "https://mainnet.eos.dfuse.io/graphql" 109336179 | tee -a banks-log.txt || exit 1
./show_log_banks || exit 1
mv *.html ../public_html/banks/ || exit 1
