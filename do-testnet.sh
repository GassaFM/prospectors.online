#!/bin/bash
cd "${0%/*}"
sleep 10
pushd testnet
source ./doit.sh
popd
