#!/bin/bash
# D language compiler with options
export dopts="-O -release -inline -boundscheck=off -i"
export dc="dmd ${dopts}"

echo Compiling...
${dc} maps.d || exit 1
${dc} pretty.d || exit 1
${dc} extract_token.d || exit 1
${dc} generate-map-css.d || exit 1
pushd mainnet || exit 1
${dc} rent-price.d -I .. || exit 1
popd || exit 1
pushd earnings || exit 1
${dc} update-logs.d || exit 1
${dc} earnings-all.d transaction.d || exit 1
popd || exit 1
pushd land || exit 1
${dc} update-logs-auction.d || exit 1
${dc} past-auctions.d || exit 1
${dc} filter-equal.d || exit 1
popd || exit 1

echo Building...
./generate-map-css || exit 1
cp map.css public_html/maps || exit 1
cp map.css public_html/testnet/maps || exit 1
