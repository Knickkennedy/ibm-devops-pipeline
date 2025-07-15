#!/usr/bin/env bash

set -e

if [ -z "$ADMIN_TOKEN" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/admin-token.sh"
fi

id=$(. "$(dirname "${BASH_SOURCE[0]}")/client-id.sh")

if [ -z "$id" ]; then
  echo "No id found for $CLIENT_ID, so creating a new client..."
  method=POST
fi

if [ -z "$BASE_URL" ]; then
  echo "No base URL found for $CLIENT_ID"
  exit 1
fi

if [ -z "$FRONT_CHANNEL_LOGOUT_URL" ]; then
  echo "No front channel logout URL found for $CLIENT_ID"
  exit 1
fi

service_accounts_enabled=false

if [ -n "$AUTHORIZATION_SERVICES" ] || [ -n "$ROLE_MAPPINGS" ]; then
  service_accounts_enabled=true
fi

if [ "$service_accounts_enabled" = true ] && [ -z "$CLIENT_SECRET" ]; then
  echo "Service accounts require a client secret"
  exit 1
fi

if [ -n "$CLIENT_SECRET" ]; then

  json_client_payload=$(cat <<EOF
{
  "clientId": "$CLIENT_ID",
  "clientAuthenticatorType": "client-secret",
  "standardFlowEnabled": ${STANDARD_FLOW:-true},
  "directAccessGrantsEnabled": ${DIRECT_ACCESS_GRANTS:-false},
  "publicClient": false,
  "secret": "$CLIENT_SECRET",
  "serviceAccountsEnabled": ${service_accounts_enabled},
  "frontchannelLogout": true,
  "attributes": {"frontchannel.logout.url": "$FRONT_CHANNEL_LOGOUT_URL" },
  "baseUrl": "${BASE_URL}",
  "redirectUris": ${REDIRECT_URIS:-[\"${BASE_URL}/*\"]},
  "webOrigins": ${WEB_ORIGINS:-[\"+\"]},
  "authorizationServicesEnabled": ${AUTHORIZATION_SERVICES:-false}
}
EOF
)

  echo "Enabling client $json_client_payload"

  response=$(curl -s -w "\n%{http_code}" -i $CAFILE -X ${method:-PUT} "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$id" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -d "${json_client_payload}")

  http_code=$(echo "$response" | tail -n1)

  body=$(echo "$response" | sed '$d')

  if [ "$http_code" -ge 300 ]; then
    echo "Failed to enable client. HTTP response code: $http_code"
    echo "Response: $body"
    exit 1
  fi

  id_location=$(echo "$body" | sed -n 's#^location:[ ]*##ip' | tr -d '\r')

else

  json_client_payload=$(cat <<EOF
{
  "clientId": "$CLIENT_ID",
  "standardFlowEnabled": ${STANDARD_FLOW:-true},
  "directAccessGrantsEnabled": ${DIRECT_ACCESS_GRANTS:-false},
  "publicClient": true,
  "frontchannelLogout": true,
  "attributes": {
    "pkce.code.challenge.method": "S256",
    "frontchannel.logout.url": "$FRONT_CHANNEL_LOGOUT_URL"
  }, 
  "baseUrl": "${BASE_URL}",
  "redirectUris": ${REDIRECT_URIS:-[\"${BASE_URL}/*\"]},
  "webOrigins": ${WEB_ORIGINS:-[\"+\"]}
}
EOF
)

  echo "Enabling client $json_client_payload"

  response="$(curl -s -w "\n%{http_code}" -i $CAFILE -X ${method:-PUT} "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$id" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -d "${json_client_payload}")"

  http_code=$(echo "$response" | tail -n1)

  body=$(echo "$response" | sed '$d')

  if [ "$http_code" -ge 300 ]; then
    echo "Failed to enable client. HTTP response code: $http_code"
    echo "Response: $body"
    exit 1
  fi

  id_location=$(echo "$body" | sed -n 's#^location:[ ]*##ip' | tr -d '\r')

fi

if [ -n "$id_location" ]; then
  echo "Location found for $CLIENT_ID is $id_location"
  id="${id_location##*/}"
fi

if [ -n "$ROLES_CLAIM" ]; then 

  response="$(curl -s -w "\n%{http_code}" $CAFILE -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$id/protocol-mappers/models" \
    -H "Authorization: Bearer $ADMIN_TOKEN")"
  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')
  if [ "$http_code" -ge 300 ]; then
    echo "Failed to get the protocol mappers. HTTP response code: $http_code"
    echo "Response: $body"
    exit 1
  fi

  echo "Protocol mappers: $body"

  mapper_enabled="$(echo "$body" | jq '.[] | select(.name=="realm_roles" and .protocolMapper=="oidc-usermodel-realm-role-mapper")')"

  echo "Mapper_enabled: $mapper_enabled"

  if [ -n "$mapper_enabled" ]; then
    echo "The protocol mapper: realm_roles is already present."
  
  else

    json_role_mapper_payload=$(cat <<EOF
{
      "name":"realm_roles",
      "protocol":"openid-connect",
      "protocolMapper":"oidc-usermodel-realm-role-mapper",
      "consentRequired":false,
      "config":{
        "claim.name":"$ROLES_CLAIM",
        "jsonType.label":"String",
        "access.token.claim":"true",
        "id.token.claim":"$ENABLE_ID_TOKEN",
        "userinfo.token.claim":"true",
        "multivalued": "true"
      }
    }
EOF
)

    echo "Adding mapper $json_role_mapper_payload"

    response="$(curl -s -w "\n%{http_code}" -i $CAFILE -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$id/protocol-mappers/models" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d "${json_role_mapper_payload}")"
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    if [ "$http_code" -ge 300 ]; then
      echo "Failed to add realm roles mapper. HTTP response code: $http_code"
      echo "Response: $body"
      exit 1
    fi

  fi

fi

if [ -n "$ROLE_MAPPINGS" ]; then
  
  user_id="$(curl -si $CAFILE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$id/service-account-user" \
      -H 'Accept: application/json' \
      -H "Authorization: Bearer $ADMIN_TOKEN" |
      sed -r -n 's/.*"id":"([^"]*)",.*/\1/p')"
  echo "user_id: $user_id"
  
  # Set an email for the service account, as it's required by Velocity
  json_service_account_email_payload=$(cat <<EOF
  {
    "email": "$CLIENT_ID@hcl-software.com"
  }
EOF
  )
  echo "Adding service account email $json_service_account_email_payload"
  response="$(curl -s -w "\n%{http_code}" -i $CAFILE -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d "${json_service_account_email_payload}")"
  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')
  if [ "$http_code" -ge 300 ]; then
    echo "Failed to set service account email. HTTP response code: $http_code"
    echo "Response: $body"
    exit 1
  fi

  for perm_group in $ROLE_MAPPINGS; do
    perm_roles="$(tr ':' ' ' <<< "${perm_group#*:}")"
    perm_client=${perm_group%%:*}
    echo perm_client: $perm_client
    perm_id="$(CLIENT_ID=$perm_client ADMIN_TOKEN=$ADMIN_TOKEN "$(dirname "${BASH_SOURCE[0]}")/client-id.sh")"
    echo perm_id: $perm_id

    roles="$(curl -si $CAFILE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$perm_id/roles" \
     -H 'Accept: application/json' \
     -H "Authorization: Bearer $ADMIN_TOKEN")"
    echo "Client Roles: $roles"

    payload=
    for role in $perm_roles; do
      p="$(sed -r -n 's/.*("id":"[^"]*","name":"'"$role"'","description":"[^"]*"),.*/\1/p' <<< "$roles")"
      echo "Checking role: $role"
      if [ -n "$p" ]; then
        echo "Adding client role: $p"
        payload="$payload,{$p}"
      fi
    done

    if [ -n "$payload" ]; then
      echo "Creating client role mapping: $payload"
      curl -i $CAFILE -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id/role-mappings/clients/$perm_id" \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -d @-<<EOF
[${payload:1}]
EOF
    fi

    realm_roles="$(curl -si $CAFILE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles" \
     -H 'Accept: application/json' \
     -H "Authorization: Bearer $ADMIN_TOKEN")"

    echo "Realm Roles: $realm_roles"
    payload=
    for realm_role in $perm_roles; do
      echo "Checking role: $role"
      p="$(sed -r -n 's/.*("id":"[^"]*","name":"'"$realm_role"'","description":"[^"]*"),.*/\1/p' <<< "$realm_roles")"
      if [ -n "$p" ]; then
        echo "Adding realm role: $p"
        payload="$payload,{$p}"
      fi
    done

    if [ -n "$payload" ]; then
      echo "Creating realm role mapping: $payload"
      curl -i $CAFILE -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id/role-mappings/realm" \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -d @-<<EOF
[${payload:1}]
EOF
    fi
  done
fi
