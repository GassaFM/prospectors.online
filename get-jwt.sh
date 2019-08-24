#!/bin/bash
curl https://auth.dfuse.io/v1/auth/issue \
       --data-binary \
       "{\"api_key\":\"`cat dfuse-server-key.txt`\"}" \
       > token.json
