#!/bin/bash
cd "${0%/*}"
source ./get-jwt.sh || exit 1
./extract_token || exit 1
