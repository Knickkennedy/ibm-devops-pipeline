#!/usr/bin/env bash

if [ -z "$ADMIN_TOKEN" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/admin-token.sh"
fi

id=$(. $(dirname "${BASH_SOURCE[0]}")/client-id.sh)

if [ -n "$id" ]; then
  echo "clientId found for $CLIENT_ID, delete this old client"

  curl -i $CAFILE -X ${method:-DELETE} "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$id" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $ADMIN_TOKEN"
fi
