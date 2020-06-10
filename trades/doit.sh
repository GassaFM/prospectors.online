#!/bin/bash
cd "${0%/*}"
../wax-trades/refresh_log_buys "https://mainnet.eos.dfuse.io/graphql" | tee -a buys-log.txt || exit 1
../wax-trades/refresh_log_sales "https://mainnet.eos.dfuse.io/graphql" | tee -a sales-log.txt || exit 1
../wax-trades/display_deals || exit 1
mv *.html ../public_html/trades/ || exit 1
shopt -s dotglob nullglob
for account in */ ; do
#	echo $account
	mkdir -p ../public_html/trades/$account || exit 1
	for f in $account* ; do
#		echo $f
		mv -f $f ../public_html/trades/$account || exit 1
	done
	rmdir $account
done
