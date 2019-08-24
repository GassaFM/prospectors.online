#!/bin/bash
cd "${0%/*}"
source ./do-main.sh | exit 1
source ./do-testnet.sh | exit 1
