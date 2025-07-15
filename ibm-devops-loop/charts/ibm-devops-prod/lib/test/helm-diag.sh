#!/usr/bin/env bash

usage() {
  echo "Usage: $0 [options] <helm release-name>"
  echo
  echo "This script is used to run helm tests and collect logs should a failure occur."
  echo
  echo "-n | --namespace <namespace>"
  echo "  The namespace where the software was installed using helm"
  echo "--force"
  echo "  Re-run helm test even when a result already exists"
  echo
  exit 1
}

parse_arguments() {
  if ! parsed=$(getopt -o n: \
	  -l namespace:,force,help \
	  -n "$(basename "$0")" -- "$@"); then
    usage
  fi
  eval set -- "$parsed"
  while true; do
    case "$1" in
      -n|--namespace) namespace="$2"; shift;;
      --force) force=force;;
      --help) usage;;
      --) shift; release="$*"; break
    esac
    shift
  done

  if [ -z "$release" ]; then
    usage
  fi
  if [ -z "$namespace" ]; then
    echo "namespace option missing"
    usage
  fi
}

last_run_start_time() {
  ${CMD_KUBECTL:-kubectl} get jobs -n "$namespace" -o=jsonpath='{.items[?(@.metadata.annotations.helm\.sh/hook=="test")].status.startTime}'
}

parse_arguments "$@"

if [ -z "$CMD_KUBECTL" ] && command -v oc >/dev/null; then
  CMD_KUBECTL=oc
fi

if ! helm status "$release" -n "$namespace" 2>&1 >/dev/null; then
  echo "Helm release $release not found in namespace $namespace"
  exit 1
fi

echo "Getting logs for helm test $release -n $namespace"

if [ -z "$force" ]; then
  since=$(last_run_start_time)
fi

if [ -n "$since" ]; then
  echo 'Using previous helm test run, use --force to always re-run helm test'
else
  : "${TIMEOUT:=300s}"
  echo "Running helm test... (can take $TIMEOUT)"
  helm test "$release" -n "$namespace" --timeout $TIMEOUT && echo "No log collection necessary, the test passed!" && exit
  since=$(last_run_start_time)
fi

echo
NAMESPACE="$namespace"
SINCE="$since"
. "$(dirname "${BASH_SOURCE[0]}")/kubectl-diag.sh"

exit 1
