#!/usr/bin/env bash
set -e

if [ -z "$ADMIN_TOKEN" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/admin-token.sh"
fi

if [ -z "$REALM_THEME" ]; then
  echo "REALM_THEME must be set."
  exit 1
fi

response=$(curl -s $CAFILE -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -w "\n%{http_code}" \
  -d @-<<EOF
{
  "loginTheme": "$REALM_THEME",
  "emailTheme": "$REALM_THEME"
}
EOF
)

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ $http_code -ge 300 ]; then
  echo "Failed to update realm theme. HTTP response code: $http_code"
  echo "Response: $body"
  exit 1
fi