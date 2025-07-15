#!/usr/bin/env bash

: "${PLATFORM:=k3s}"

if [ "$SKIP_K8S" != true ]; then
  SKIP_K8S=true

  case "$PLATFORM" in
    k3s)
      . "$(dirname "${BASH_SOURCE[0]}")/k3s/main.sh"
      ;;
  esac
fi
