#!/bin/bash
cd "${0%/*}"
rm -f *.json || exit 1
./refresh-logs "https://mainnet.eos.dfuse.io/v0/search/transactions" \
    "account:prospectorsc action:withdraw" \
    "account:prospectorsg action:transfer data.to:prospectorsc" || exit 1
export logid1=5a9e5705e2abf6227ccb87e6ef44435bec42f7cebc7d78b0bb88a92b42f6cd63
./filter-equal <$logid1.log >$logid1.log2 && mv $logid1.log2 $logid1.log || exit 1
export logid2=173b76ca56b8d4d1f71cc98ceec53906b8f4e39861e2274a0246da4e7ef8dd53
./filter-equal <$logid2.log >$logid2.log2 && mv $logid2.log2 $logid2.log || exit 1
./earnings-all prospectorsc "https://mainnet.eos.dfuse.io/v0/block_id/by_time" \
    "https://mainnet.eos.dfuse.io/v0/state/table" \
    "account:prospectorsc action:withdraw" \
    "account:prospectorsg action:transfer data.to:prospectorsc" \
    alliance-b alliance-ek alliance-ek-plus alliance-support alliance-tgt || exit 1
mv *.html ../public_html/earnings/ || exit 1
rm -f *.json || exit 1
