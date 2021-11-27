#!/bin/bash
cd "${0%/*}"
source ./getter-binary.sh loc uint64 || exit 1
#source ./getter-binary.sh worker uint64 || exit 1
#source ./getter-binary.sh order uint64 || exit 1
source ./getter-binary.sh account name || exit 1
#source ./getter-binary.sh market uint64 || exit 1
#source ./getter-binary.sh world uint64 || exit 1
#source ./getter-binary.sh stat uint64 || exit 1
#source ./getter-binary.sh auction uint64 || exit 1
source ./getter-scopelist.sh storage || exit 1
source ./getter-allscopes.sh storage uint64 || exit 1
../stores/stores || exit 1
mv stores.*.txt ../public_html/grand/stores/ || exit 1
mv stores.*.html ../public_html/grand/stores/ || exit 1
mv stores.html ../public_html/grand/stores/ || exit 1
