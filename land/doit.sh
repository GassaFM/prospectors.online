#!/bin/bash
cd "${0%/*}"
./refresh-logs-auction "https://mainnet.eos.dfuse.io/graphql" "account:prospectorsc (action:endauction OR action:endlocexpr OR action:endlocsale OR action:mkfreeloc)" || exit 1
export logid1=1bfa5af5230749c271f8a3869bbff43b501385b83c25a76af24669161e674d55
./filter-equal <$logid1.log >$logid1.log2 && mv $logid1.log2 $logid1.log || exit 1
./past-auctions prospectorsc || exit 1
mv *.html ../public_html/land/ || exit 1
