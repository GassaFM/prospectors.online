#!/bin/bash
cd "${0%/*}"
../land/refresh-logs-auction "https://wax.dfuse.eosnation.io/graphql" "account:prospectorsn (action:endauction OR action:endlocexpr OR action:endlocsale OR action:mkfreeloc)" || exit 1
export logid1=3a290f10ca50bb6f37e9827094302be282c59d3574a4f0f4f0309c296ccd7061
../land/filter-equal <$logid1.log >$logid1.log2 && mv $logid1.log2 $logid1.log || exit 1
../land/past-auctions prospectorsn || exit 1
mv *.html ../public_html/grand/land/ || exit 1
