#!/bin/bash
cd "${0%/*}"
export destination=../public_html/grand
source ./getter-binary.sh loc uint64 || exit 1
source ./getter-binary.sh worker uint64 || exit 1
#source ./getter-binary.sh order uint64 || exit 1
source ./getter-binary.sh account name || exit 1
source ./getter-binary.sh alliance name || exit 1
#source ./getter-binary.sh market uint64 || exit 1
#source ./getter-binary.sh world uint64 || exit 1
source ./getter-binary.sh stat uint64 || exit 1
source ./getter-binary.sh auction uint64 || exit 1
../maps grandland || exit 1
mv *.html $destination/maps/ || exit 1
../mainnet/rent-price || exit 1
mv rent-price.html $destination/ || exit 1
