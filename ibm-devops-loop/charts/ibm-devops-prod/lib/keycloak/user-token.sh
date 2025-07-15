#!/usr/bin/env bash

_json_get() {
  sed -r -n 's/.*"'$1'":"([^"]*)".*/\1/p'
}

_curl() {
  curl -s $CAFILE -u "$CLIENT_ID:$CLIENT_SECRET" \
       "$KEYCLOAK_URL/realms/$REALM_NAME/protocol/openid-connect/token" "$@"
}

CLIENT_BEARER="$(_curl \
  -F grant_type=client_credentials \
  | _json_get access_token)"

USER_TOKEN="$(_curl \
  -F grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
  -F "subject_token=$CLIENT_BEARER" \
  -F "requested_subject=$USER_NAME" \
  | _json_get access_token)"

if [[ -z "$USER_TOKEN" ]]; then
  echo "ERROR: no access_token"
  exit 1
fi
