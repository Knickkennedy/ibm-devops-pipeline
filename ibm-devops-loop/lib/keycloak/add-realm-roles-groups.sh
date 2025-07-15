#!/bin/bash
export LC_ALL=C
set -e 

. "$(dirname "${BASH_SOURCE[0]}")/admin-token.sh"

if [ -z "$REALM_NAME" ] || [ -z "$REALM_ROLES" ] || [ -z "$REALM_GROUPS" ]; then
  echo "Usage: REALM_NAME=<realm> REALM_ROLES=<roles> REALM_GROUPS=<groups> ./add-realm-roles-groups.sh"
  echo "Example: REALM_NAME=devops-platform REALM_ROLES='[{\"name\":\"ROLE_USER\",\"description\":\"User role\"},{\"name\":\"ROLE_ADMIN\",\"description\":\"Admin role\"}]' REALM_GROUPS='[{\"name\":\"Users\",\"realmRoles\":[\"ROLE_USER\"]},{\"name\":\"Admins\",\"realmRoles\":[\"ROLE_ADMIN\"]}]' ./add-realm-roles-groups.sh"
  exit 1
fi

echo "Creating or updating realm $REALM_NAME"
curl -sif $CAFILE -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
        "registrationEmailAsUsername": true
      }'
      
# Create or update roles
echo "$REALM_ROLES" | jq -c '.[]' | while read -r role; do

  role_name=$(echo "$role" | jq -r '.name' )

  role_id=$(curl -sf $CAFILE -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles/$role_name" \
    -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.id' )
  
  if [ -z "$role_id" ]; then
    echo "Creating role $role"
    curl -sif $CAFILE -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d "$role"
  else
    echo "Updating role $role with ID $role_id"
    curl -sif $CAFILE -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles-by-id/$role_id" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d "$role"
  fi
done

# Create or update groups
echo "$REALM_GROUPS" | jq -c '.[]' | while read -r group; do
  group_name=$(echo "$group" | jq -r '.name')

  group_id=$(curl -sf $CAFILE -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/groups?search=$group_name" \
    -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r 'if length == 0 then empty else .[0].id end')
  
  if [ -z "$group_id" ]; then

    echo "Creating group $group"
    curl -sif $CAFILE -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/groups" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d "$group"
  else

    echo "Updating group $group with ID $group_id"
    curl -sif $CAFILE -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME/groups/$group_id" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d "$group"
  fi
  
  # Update role mappings as Keycloak does not support this in the group creation API
  realm_roles=$(echo "$group" | jq -r '.realmRoles')
  if [ -n "$realm_roles" ]; then
    
    role_mapping="[]"
    for role_name in $(echo "$realm_roles" | jq -r '.[]'); do

      role_id=$(curl -sf $CAFILE -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles/$role_name" \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.id')
    
      role_mapping=$(echo "$role_mapping" | jq --arg id "$role_id" --arg name "$role_name" '. + [{id: $id, name: $name}]')
    done

    echo "Assigning roles $role_mapping to group $group_name with ID $group_id"

    curl -sif $CAFILE -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/groups/$group_id/role-mappings/realm" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -d "$role_mapping"
  fi
  
done