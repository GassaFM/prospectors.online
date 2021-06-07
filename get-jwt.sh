#!/bin/bash
curl https://auth.eosnation.io/v1/auth/issue \
       --data-binary \
       "{\"api_key\":\"`cat dfuse-server-key.txt`\"}" \
       > token.json
