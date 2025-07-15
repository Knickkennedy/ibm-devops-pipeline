#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../cli.sh"

# INGRESS_DOMAIN=

DEFAULT_IMAGE_REGISTRY=cp.icr.io/cp

ip-resolve() {
  (getent hosts "$1" | cut -f1 -d' ' \
   || nslookup "$1" 2>/dev/null | sed -ne '/^Name:/,/^Address/p' | grep -oP '^Addresse?s?: *\K\S+' \
   || ping -c1 -t1 -w0 "$1" | grep -oP '[^(]\(\K[^)]*' \
  ) | head -n1
}

: "${INGRESS_IP:=$(ip-resolve "$INGRESS_DOMAIN")}"
: "${MANIFESTS_DIR:=$(dirname "${BASH_SOURCE[0]}")}"
: "${PLATFORM:=k3s}"

if [ "$SKIP_INGRESS" != true ]; then
  echo-head Emissary

  $RUNUSER kubectl create namespace emissary 2>/dev/null || true

  cat "$MANIFESTS_DIR/emissary-crds.yaml" |
    ( [ -z "$IMAGE_REGISTRY" ] && cat || sed -e "s#${DEFAULT_IMAGE_REGISTRY//./\.}/#$IMAGE_REGISTRY/#g" ) |
    $RUNUSER kubectl apply -f - >/dev/null

  _tick
  kubectl wait deployment emissary-apiext --for condition=available -n emissary-system --timeout=$TIMEOUT

  # Remove when https://github.com/emissary-ingress/emissary/issues/4275 is resolved
  echo -n "Waiting for emissary ca to be generated"
  while ! kubectl get secret emissary-ingress-webhook-ca --namespace emissary-system >/dev/null 2>&1; do echo -n "."; sleep 1; done
  echo
  echo-info "Redeploying emissary pod"
  kubectl delete po -n emissary-system -l app.kubernetes.io/name=emissary-apiext
  _tick
  kubectl wait deployment emissary-apiext --for condition=available -n emissary-system --timeout=$TIMEOUT

  cat "$MANIFESTS_DIR/emissary-emissaryns-$PLATFORM.yaml" |
    ( [ -z "$IMAGE_REGISTRY" ] && cat || sed -e "s#${DEFAULT_IMAGE_REGISTRY//./\.}/#$IMAGE_REGISTRY/#g" ) |
    ( [ -z "$EXTRA_PORTS" ] && cat || sed -e "
s/\( *\)  targetPort: 8443/\0\
\n\1- name: ${EXTRA_PORTS%:*}\
\n\1  port: ${EXTRA_PORTS#*:}\
\n\1  targetPort: ${EXTRA_PORTS#*:}\
\n\1  protocol: TCP/;
s/\( *\)  containerPort: 8443/\0\
\n\1- name: ${EXTRA_PORTS%:*}\
\n\1  containerPort: ${EXTRA_PORTS#*:}\
\n\1  protocol: TCP/" ) |
    sed -e "s/\$INGRESS_IP/$INGRESS_IP/g" |
    $RUNUSER kubectl apply -f - >/dev/null

  if [ "$PLATFORM" = k3s ] && command -v firewall-cmd >/dev/null && [ "running" = "$(firewall-cmd --state 2>/dev/null)" ]; then
    if [ -n "$EXTRA_PORTS" ]; then
      firewall-cmd -q --add-port="${EXTRA_PORTS#*:}/tcp" --permanent
    fi

    firewall-cmd -q --add-service=http --add-service=https --permanent
    firewall-cmd -q --reload
  fi
fi
