#!/bin/bash
source ./getter-binary.sh loc uint64 || exit 1
source ./getter-binary.sh worker uint64 || exit 1
#source ./getter-binary.sh order uint64 || exit 1
source ./getter-binary.sh account name || exit 1
source ./getter-binary.sh alliance name || exit 1
#source ./getter-binary.sh market uint64 || exit 1
#source ./getter-binary.sh world uint64 || exit 1
source ./getter-binary.sh stat uint64 || exit 1
source ./getter-binary.sh auction uint64 || exit 1
../maps testnet
mv *.html ../public_html/testnet/maps/
