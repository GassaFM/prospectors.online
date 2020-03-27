#!/bin/bash
cd "${0%/*}"
../banks/refresh_log_banks "https://mainnet.wax.dfuse.io/graphql" 44748653 | tee -a banks-log.txt || exit 1
../banks/show_log_banks || exit 1
mv *.html ../public_html/wax/banks/ || exit 1
