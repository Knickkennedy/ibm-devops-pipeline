#!/usr/bin/env bash

curl -si $CAFILE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients?clientId=$CLIENT_ID" \
 -H 'Accept: application/json' \
 -H "Authorization: Bearer $ADMIN_TOKEN" |
 sed -r -n 's/.*"id":"([^"]*)","clientId".*/\1/p'
