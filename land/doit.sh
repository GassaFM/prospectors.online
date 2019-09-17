#!/bin/bash
cd "${0%/*}"
./update-logs-auction "account:prospectorsc (action:endauction OR action:endlocexpr OR action:endlocsale)" || exit 1
./past-auctions || exit 1
mv *.html ../public_html/land/ || exit 1
