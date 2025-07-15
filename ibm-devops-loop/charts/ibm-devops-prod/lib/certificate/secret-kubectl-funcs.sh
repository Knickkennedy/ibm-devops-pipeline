#!/usr/bin/env bash

# Use kubectl to manage secrets (kept in sync with secret-curl-funcs.sh).

secret-has() {
  : "${CMD_KUBECTL:=kubectl}"

  $CMD_KUBECTL get secret "$1" -n "$NAMESPACE" >/dev/null 2>/dev/null
}

secret-get() {
  : "${CMD_KUBECTL:=kubectl}"

  $CMD_KUBECTL get secret "$1" -n "$NAMESPACE" -o "jsonpath={.data['${2//./\\.}']}" | base64 -d
}

secret-create() {
  : "${CMD_KUBECTL:=kubectl}"

  $CMD_KUBECTL create secret generic "$1" -n "$NAMESPACE" \
    --type=kubernetes.io/tls \
    --from-file=tls.key="$2" \
    --from-file=tls.crt="$3" \
    --from-file=ca.crt="$4" >/dev/null
}

secret-update() {
  : "${CMD_KUBECTL:=kubectl}"

  $CMD_KUBECTL create secret generic "$1" -n "$NAMESPACE" \
    --type=kubernetes.io/tls \
    --from-file=tls.key="$2" \
    --from-file=tls.crt="$3" \
    --from-file=ca.crt="$4" \
    --save-config --dry-run=client -o yaml \
  | $CMD_KUBECTL apply -f - >/dev/null
}
