#!/bin/bash
# D language compiler with options
export dopts="-O -release -inline -boundscheck=off -i"
export dc="ldmd2 ${dopts}"

function compile () {
	echo Compiling $@
	${dc} $@ || exit 1
}

echo Compiling...
compile maps.d
compile pretty.d
compile extract_token.d
compile generate-map-css.d

pushd mainnet || exit 1
compile rent-price.d -I ..
popd || exit 1

pushd land || exit 1
compile refresh-logs-auction.d
compile past-auctions.d
compile filter-equal.d
popd || exit 1

pushd earnings || exit 1
compile refresh-logs.d
compile earnings-all.d -I ..
cp ../land/filter-equal . || exit 1
popd || exit 1

pushd stores || exit 1
compile stores.d -I ..
popd || exit 1

pushd wax-trades || exit 1
compile display_deals.d -I ..
compile refresh_log_buys.d -I ..
compile refresh_log_sales.d -I ..
popd || exit 1

pushd banks || exit 1
compile refresh_log_banks.d -I ..
compile show_log_banks.d -I ..
popd || exit 1

echo Building...
./generate-map-css || exit 1
cp map.css public_html/maps || exit 1
cp map.css public_html/testnet/maps || exit 1
cp map.css public_html/wax/maps || exit 1

cp public_html/maps/*.js public_html/testnet/maps || exit 1
cp public_html/maps/*.js public_html/wax/maps || exit 1
