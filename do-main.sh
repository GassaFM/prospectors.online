#!/bin/bash
cd "${0%/*}"
sleep 5
pushd mainnet
source ./doit.sh
popd
