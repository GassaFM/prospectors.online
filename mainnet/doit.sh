#!/bin/bash
source ./getter-uint64.sh loc || exit 1
source ./getter-uint64.sh worker || exit 1
#source ./getter-uint64.sh order || exit 1
#source ./getter.sh account || exit 1
#source ./getter-uint64.sh market || exit 1
#source ./getter-uint64.sh world || exit 1
source ./getter-uint64.sh stat || exit 1
source ./getter-uint64.sh auction || exit 1
../maps || exit 1
mv *.html ../public_html/maps/ || exit 1
./rent-price || exit 1
mv rent-price.html ../public_html/ || exit 1
