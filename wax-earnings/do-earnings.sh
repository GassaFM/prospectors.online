#!/bin/bash
cd "${0%/*}"
rm -f *.json || exit 1
../earnings/refresh-logs "https://wax.dfuse.eosnation.io/v0/search/transactions" \
    "account:prospectorsc action:withdraw" \
    "account:prospectorsw action:transfer data.to:prospectorsc" || exit 1
export logid1=5a9e5705e2abf6227ccb87e6ef44435bec42f7cebc7d78b0bb88a92b42f6cd63
#../earnings/filter-equal <$logid1.log >$logid1.log2 && mv $logid1.log2 $logid1.log || exit 1
export logid2=173b76ca56b8d4d1f71cc98ceec53906b8f4e39861e2274a0246da4e7ef8dd53
#../earnings/filter-equal <$logid2.log >$logid2.log2 && mv $logid2.log2 $logid2.log || exit 1
./refresh_log_ft "https://wax.dfuse.eosnation.io/graphql" || exit 1
../earnings/earnings-all prospectorsc "https://wax.dfuse.eosnation.io/v0/block_id/by_time" \
    "https://wax.dfuse.eosnation.io/v0/state/table" \
    "account:prospectorsc action:withdraw" \
    "account:prospectorsw action:transfer data.to:prospectorsc" \
    alliance-ek || exit 1
mv *.html ../public_html/wax/earnings/ || exit 1
rm -f *.json || exit 1
