#!/bin/bash
cd "${0%/*}"
../wax-trades/refresh_log_buys prospectorsq "https://eos.dfuse.eosnation.io/graphql" | tee -a buys-log.txt || exit 1
../wax-trades/refresh_log_sales prospectorsq "https://eos.dfuse.eosnation.io/graphql" | tee -a sales-log.txt || exit 1
../wax-trades/refresh_log_station prospectorsq "https://eos.dfuse.eosnation.io/graphql" | tee -a station-log.txt || exit 1
../wax-trades/display_deals prospectorsq || exit 1
mv *.html ../public_html/boom/trades/ || exit 1
shopt -s dotglob nullglob
for account in */ ; do
#	echo $account
	mkdir -p ../public_html/boom/trades/$account || exit 1
	for f in $account* ; do
#		echo $f
		mv -f $f ../public_html/boom/trades/$account || exit 1
	done
	rmdir $account
done
