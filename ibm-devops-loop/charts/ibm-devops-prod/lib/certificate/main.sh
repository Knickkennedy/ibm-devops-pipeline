#!/usr/bin/env bash

usage() {
  echo "Usage: $0 -n <namespace> -s <secret-name> domain.local"
  echo
  echo "Create a certificate with a self-signed CA for a domain."
  echo
  echo "Options:"
  echo "-f | --force"
  echo "  Replace existing certificate."
  echo "-n | --namespace <namespace>"
  echo "  The namespace where a secret to contain the certificate/main.should be created."
  echo "-s | --secret <secret-name>"
  echo "  The name of the secret to create to contain the certificate. (default: ingress)"
  echo "domain.local"
  echo "  The domain to create a certificate for."
  exit 1
}

set -e

cd "$(dirname "$0")" || exit 1

. funcs.sh
. secret-kubectl-funcs.sh

if [ -z "$CMD_KUBECTL" ] && command -v oc >/dev/null; then
  CMD_KUBECTL=oc
fi
export MSYS_NO_PATHCONV=1
openssl-assert

if ! parsed=$(getopt -o fn:s: \
 -l force,namespace:,secret:: \
 -n "$(basename "$0")" -- "$@"); then
  usage
fi
eval set -- "$parsed"

INGRESS_DOMAIN=
INGRESS_SECRET=ingress
NAMESPACE=
CERT_OVERWRITE=false
while true; do
  case "$1" in
    -f|--force) CERT_OVERWRITE=true;;
    -n|--namespace) NAMESPACE="$2"; shift;;
    -s|--secret) INGRESS_SECRET="$2"; shift;;
    --) shift; INGRESS_DOMAIN="$1"; break;;
     *) exit 1;;
  esac
  shift
done

if [ -z "$NAMESPACE" ] || [ -z "$INGRESS_SECRET" ] || [ -z "$INGRESS_DOMAIN" ]; then
  usage
fi

cert-make
cert-show
