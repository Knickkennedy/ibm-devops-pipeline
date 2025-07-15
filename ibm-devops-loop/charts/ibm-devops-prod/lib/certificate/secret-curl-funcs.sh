#!/usr/bin/env bash

# Use curl to manage secrets (kept in sync with secret-kubectl-funcs.sh).

APISERVER=https://kubernetes.default.svc
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
TOKEN=$(cat ${SERVICEACCOUNT}/token)
CACERT=${SERVICEACCOUNT}/ca.crt

secret-has() {
  [[ "$(curl --cacert ${CACERT} -s -o /dev/null -w '%{http_code}' \
  --header "Authorization: Bearer ${TOKEN}" \
  --header 'Accept: application/yaml' \
  "${APISERVER}/api/v1/namespaces/${NAMESPACE}/secrets/$1")" -eq 200 ]]
}

secret-get() {
  curl --cacert ${CACERT} -s \
  --header "Authorization: Bearer ${TOKEN}" \
  --header 'Accept: application/yaml' \
  "${APISERVER}/api/v1/namespaces/${NAMESPACE}/secrets/$1" \
  | grep -oP "^ *\Q$2\E: \K.*" | base64 -d
}

secret-create() {
  curl --cacert ${CACERT} -s -o /dev/null -w '%{http_code}' -X POST \
  --header "Authorization: Bearer ${TOKEN}" \
  --header 'Content-Type: application/yaml' \
  "${APISERVER}/api/v1/namespaces/${NAMESPACE}/secrets" \
  --data-binary @- <<EOF
kind: Secret
apiVersion: v1
metadata:
  name: $1
type: kubernetes.io/tls
data:
  tls.key: $(cat "$2" | base64 -w0)
  tls.crt: $(cat "$3" | base64 -w0)
  ca.crt: $(cat "$4" | base64 -w0)
EOF
}

secret-update() {
  curl --cacert ${CACERT} -s -o /dev/null -w '%{http_code}' -X PUT \
  --header "Authorization: Bearer ${TOKEN}" \
  --header 'Content-Type: application/yaml' \
  "${APISERVER}/api/v1/namespaces/${NAMESPACE}/secrets/$1" \
  --data-binary @- <<EOF
kind: Secret
apiVersion: v1
metadata:
  name: $1
type: kubernetes.io/tls
data:
  tls.key: $(cat "$2" | base64 -w0)
  tls.crt: $(cat "$3" | base64 -w0)
  ca.crt: $(cat "$4" | base64 -w0)
EOF
}
