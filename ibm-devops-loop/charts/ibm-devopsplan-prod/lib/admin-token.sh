#!/usr/bin/env bash

ADMIN_TOKEN_FILE=$(mktemp -p /tmp admin-token.XXX)

curl -si $CAFILE -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=$ADMIN_NAME" \
  --data-urlencode "password=$ADMIN_PASS" \
  -d grant_type=password \
  -d client_id=admin-cli >"$ADMIN_TOKEN_FILE"

ADMIN_TOKEN=$(sed -r -n 's/.*"access_token":"([^"]*)".*/\1/p' "$ADMIN_TOKEN_FILE")
if [[ -z "$ADMIN_TOKEN" ]]; then
  cat "$ADMIN_TOKEN_FILE"
  rm "$ADMIN_TOKEN_FILE"
  echo "ERROR: no access_token in $ADMIN_TOKEN_FILE"
  exit 1
fi

rm "$ADMIN_TOKEN_FILE"
