#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../cli.sh"

NAMESERVERS=""
FILE=""
NO_FILE=0

usage() {
  echo $1
  echo "This script configures the CoreDNS service in the k3s cluster."
  echo "With no arguments it attempts to find an appropriate file from which to read"
  echo "the IP addresses of nameservers to which DNS requests should be forwarded."
  echo "The behavior may be modified with the following options:"
  echo
  echo "-s | --server <nameserver>"
  echo "Add the given nameserver to the list of those to add.  These are in addition to"
  echo "any found in a file.  This may appear multiple times."
  echo
  echo "-f | --file <filename>"
  echo "Don't attempt to find a file, but use the one specified.  The file should have"
  echo "lines of the form 'nameserver <ip address>.  All other lines are ignored."
  echo
  echo "-n | --no-file"
  echo "Prevents the script from looking for a file from which to parse nameservers."
  echo "This cannot be used in conjuction with --file."
  echo
  echo "-p | --preferred-filter"
  echo "Prefer addresses which match this filter.  If this is specified any"
  echo "non-matching nameservers found in the parsed file are not included."
  echo "e.g. --preferred-filter=10."
  echo "will only include nameservers of the form: 10.nnn.nnn.nnn"

  exit 1
}

# $1    - name
# $2... - args
parse-command-line() {
  local name
  name="$1"
  shift
  if ! parsed=$(getopt -o is:f:np: -l server:,file:,no-file,preferred-filter: --name $name -- "$@"); then
     usage "$name"
  fi
  set -- $parsed
  while [ $# -gt 0 ]; do
    case "$1" in
      -s|--server)
              shift
	      append-to-nameservers $(trim-argument "$1")
	      ;;
      -f|--file)
	      shift
	      if [ "$FILE" != "" ]; then
                echo-error "only one file may be specified"
		usage "$name"
              fi
	      FILE=$(trim-argument "$1")
	      ;;
      -n|--no-file) NO_FILE=1 ;;
      -p|--preferred-filter)
	      shift
	      PREFERRED_FILTERS=$(append-to-list "$PREFERRED_FILTERS" \
		      $(trim-argument "$1"))
	      ;;
    esac
    shift
  done
  if [ "$FILE" != "" ] && [ $NO_FILE -eq 1 ]; then
    echo-error "cannot specify both --file and --no-file"
    usage "$name"
  fi
}

is-using-systemd() {
  if command -v systemctl > /dev/null 2>&1 && \
    systemctl is-active --type=service systemd-resolved > /dev/null 2>&1; then
      return 0
  fi
  return 1
}

# $1 - list
# $2 - items(s) to append
append-to-list() {
  local current
  current=$1
  shift
  if [ "$current" != "" ]; then
    echo "$current $*"
  else
    echo "$@"
  fi
}

# $1... - nameservers to add to NAMESERVERS list
append-to-nameservers() {
  NAMESERVERS=$(append-to-list "$NAMESERVERS" "$@")
}

# $1 - file to parse for namesever ip addresses
#
# Sets the NAMESERVERS to be those found in the given file
parse-nameservers() {
  for ns in $(grep -ie "^nameserver\s\+" $1 | awk '{print $2}'); do
    append-to-nameservers "$ns"
  done
}

# $1 - nameserver
# $2 - filter
nameserver-matches-filter() {
  echo "$1" | grep -q -e "^$2"
}

# $1 - nameserver
# Return 0 if $1 matches one of the $PREFERRED_FILTERS
is-preferred() {
  for f in $PREFERRED_FILTERS; do
    if nameserver-matches-filter "$1" "$f"; then
      return 0
    fi
  done
  return 1
}

# Clean up the NAMESERVERS list.
sanitise-nameservers() {
  local sanitised

  sanitised=$(
    for ns in $NAMESERVERS; do
      if is-preferred $ns; then
        echo "$ns"
      fi
    done)

  if [ "$sanitised" = "" ]; then
    sanitised=$(
      for ns in $NAMESERVERS; do
        if  ! nameserver-matches-filter $ns "127."; then
          echo "$ns"
        fi
      done)
  fi

  NAMESERVERS="$sanitised"
}

remove-duplicate-nameservers() {
  NAMESERVERS=$(
    for ns in $NAMESERVERS; do
      echo "$ns"
    done | sort -u)
  NAMESERVERS=$(echo -n $NAMESERVERS)
}

echo-head DNS

parse-command-line $(basename "$0") "$@"

: "${PREFERRED_FILTERS:=10.}"

CLI_NAMESERVERS="$NAMESERVERS"
NAMESERVERS=""

exit-if-root

if [ "$FILE" = "" ] && [ $NO_FILE -eq 0 ]; then
  if is-using-systemd; then
    FILE=/run/systemd/resolve/resolv.conf
  else
    FILE=/etc/resolv.conf
  fi
fi

if [ $NO_FILE -eq 0 ]; then
  echo "nameservers parsed from ${FILE}"
  parse-nameservers "$FILE"
fi

sanitise-nameservers
append-to-nameservers "$CLI_NAMESERVERS"

if [ "$NAMESERVERS" = "" ]; then
  echo-error "The nameserver list is empty, aborting"
  exit 1
fi

remove-duplicate-nameservers

rm -f "$K3S_RESOLV_CONF"
mkdir -p "$(dirname $K3S_RESOLV_CONF)"
echo "nameservers set to"
for ns in $NAMESERVERS; do
  echo "  $ns"
  echo "nameserver $ns" >> "$K3S_RESOLV_CONF"
done

if k3s-is-installed && k3s-is-running; then
  $RUNUSER kubectl delete pod -n kube-system -l k8s-app=kube-dns
  $RUNUSER kubectl get pod -n kube-system -l k8s-app=kube-dns
fi
