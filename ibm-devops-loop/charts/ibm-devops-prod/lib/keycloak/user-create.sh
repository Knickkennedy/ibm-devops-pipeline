#!/usr/bin/env bash

USER_EMAIL=$USER_NAME@email.test
: "${USER_PASS:=$(cat /dev/urandom | head -c64 | sha256sum | cut -d " " -f1 | tr -d '\n')}"

curl -si $CAFILE -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d @-<<EOF
{
"username":"$USER_NAME",
"firstName":"$USER_NAME_FIRST",
"lastName":"$USER_NAME_LAST",
"email":"$USER_EMAIL",
"emailVerified": false,
"enabled":"true",
"groups":${USER_GROUPS:-[]},
"credentials":[{"type":"password",
                "value":"$USER_PASS",
                "temporary":false}]
}
EOF
