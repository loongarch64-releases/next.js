#!/bin/sh
set -eu

UPSTREAM_OWNER=vercel
UPSTREAM_REPO=next.js

curl -s https://api.github.com/repos/"$UPSTREAM_OWNER"/"$UPSTREAM_REPO"/releases/latest \
     | jq -r ".tag_name"
