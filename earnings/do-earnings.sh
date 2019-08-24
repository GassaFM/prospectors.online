#!/bin/bash
cd "${0%/*}"
./refresh-logs || exit 1
./earnings-all || exit 1
mv *.html ../public_html/earnings/ || exit 1
rm *.json || exit 1
