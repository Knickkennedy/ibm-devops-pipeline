#!/usr/bin/env bash

USER_FILE=$(mktemp -p /tmp user.XXX)

curl -si $CAFILE -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users?username=$USER_NAME" \
  -H "Authorization: Bearer $ADMIN_TOKEN" >"$USER_FILE"

USER_ID=$(sed -r -n 's/.*"id":"([^"]*)".*/\1/p' "$USER_FILE")
if [[ -z "$USER_ID" ]]; then
  cat "$USER_FILE"
  echo no user $USER_NAME user exists
else
  echo
  echo delete user $USER_NAME with id $USER_ID
  curl -si $CAFILE -X DELETE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$USER_ID" \
    -H "Authorization: Bearer $ADMIN_TOKEN"
fi

rm "$USER_FILE"
