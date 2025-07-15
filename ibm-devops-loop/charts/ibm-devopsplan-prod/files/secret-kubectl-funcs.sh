#!/usr/bin/env bash

# Use kubectl to manage secrets (kept in sync with secret-curl-funcs.sh).

secret-has() {
  : "${kubectl:=kubectl}"

  $kubectl get secret "$1" -n "$NAMESPACE" >/dev/null 2>/dev/null
}

secret-get() {
  : "${kubectl:=kubectl}"

  $kubectl get secret "$1" -n "$NAMESPACE" -o "jsonpath={.data['${2//./\\.}']}" | base64 -d
}

secret-create() {
  : "${kubectl:=kubectl}"

  $kubectl create secret generic "$1" -n "$NAMESPACE" \
    --type=kubernetes.io/tls \
    --from-file=tls.key="$2" \
    --from-file=tls.crt="$3" \
    --from-file=ca.crt="$4" >/dev/null
}

secret-update() {
  : "${kubectl:=kubectl}"

  $kubectl create secret generic "$1" -n "$NAMESPACE" \
    --type=kubernetes.io/tls \
    --from-file=tls.key="$2" \
    --from-file=tls.crt="$3" \
    --from-file=ca.crt="$4" \
    --save-config --dry-run=client -o yaml \
  | $kubectl apply -f - >/dev/null
}
