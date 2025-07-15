#!/usr/bin/env bash

if [ -z "$ADMIN_TOKEN" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/admin-token.sh"
fi

if [ -n "$REALM_THEME" ]; then
  THEME='"loginTheme":"'$REALM_THEME'","accountTheme":"'$REALM_THEME'",'
fi

curl -si $CAFILE -X POST "$KEYCLOAK_URL/admin/realms" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d @-<<EOF
{
"realm":"$REALM_NAME",
"enabled":"true",
"roles":{"realm":[{"name":"ROLE_ADMIN","description":"Administrator role"}]},
"groups":[{"name":"Admins","realmRoles":["ROLE_ADMIN"]}],
$THEME
"bruteForceProtected":true,
"passwordPolicy":"length(8)",
"failureFactor": 10,
"minimumQuickLoginWaitSeconds":300,
"waitIncrementSeconds":300,
"internationalizationEnabled":true,
"supportedLocales":["cs", "de", "en", "es", "fr", "hu", "it", "ja", "ko", "pl", "pt-BR", "ru", "tr", "zh-cn", "zh-tw"],
"registrationAllowed":${SIGNUP-false}
}
EOF