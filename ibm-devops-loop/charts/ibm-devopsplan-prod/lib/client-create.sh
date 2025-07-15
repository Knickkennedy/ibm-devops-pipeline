#!/usr/bin/env bash

if [ -z "$ADMIN_TOKEN" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/admin-token.sh"
fi

id=$(. "$(dirname "${BASH_SOURCE[0]}")/client-id.sh")

if [ -z "$id" ]; then
  echo "No id found for $CLIENT_ID, so creating a new client..."
  method=POST
fi

id_location="$(curl -i $CAFILE -X ${method:-PUT} "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$id" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d @-<<EOF | sed -n 's#^location:[ ]*##ip' | tr -d '\r'
{
"clientId": "$CLIENT_ID",
"clientAuthenticatorType": "client-secret",
"directAccessGrantsEnabled": false,
"publicClient": false,
"secret": "$CLIENT_SECRET",
"serviceAccountsEnabled": true,
"standardFlowEnabled": ${STANDARD_FLOW:-false},
"frontchannelLogout": $(if [ -z "${LOGOUT_FRAGMENT}" ]; then echo false; else echo true; fi),
${LOGOUT_FRAGMENT}${LOGOUT_FRAGMENT:+,}
${BASE_URL}${BASE_URL:+,}
"authorizationServicesEnabled": ${AUTHORIZATION_SERVICES:-false}
}
EOF
)"

if [ -n "$id_location" ]; then
  echo "Location found for $CLIENT_ID is $id_location"
  id="${id_location##*/}"
fi

if [ -n "$ROLE_MAPPINGS" ]; then
  user_id="$(curl -si $CAFILE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$id/service-account-user" \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer $ADMIN_TOKEN" |
    sed -r -n 's/.*"id":"([^"]*)",.*/\1/p')"

  for perm_group in $ROLE_MAPPINGS; do
    perm_roles="$(tr ':' ' ' <<< "${perm_group#*:}")"
    perm_client=${perm_group%%:*}
    perm_id="$(CLIENT_ID=$perm_client ADMIN_TOKEN=$ADMIN_TOKEN "$(dirname "${BASH_SOURCE[0]}")/client-id.sh")"

    roles="$(curl -si $CAFILE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$perm_id/roles" \
     -H 'Accept: application/json' \
     -H "Authorization: Bearer $ADMIN_TOKEN")"

    payload=
    for role in $perm_roles; do
      p="$(sed -r -n 's/.*("id":"[^"]*","name":"'"$role"'","description":"[^"]*"),.*/\1/p' <<< "$roles")"
      payload="$payload,{$p}"
    done

    curl -i $CAFILE -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id/role-mappings/clients/$perm_id" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d @-<<EOF
[${payload:1}]
EOF

  done
fi
