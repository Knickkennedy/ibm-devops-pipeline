#!/usr/bin/env bash

set -e

RESET="\e[49m\e[39m"
#shellcheck disable=SC2034
BRAND="\e[104m\e[97m"
#shellcheck disable=SC2034
ERROR="\e[101m\e[97m ERROR:"
#shellcheck disable=SC2034
WARNING="\e[105m\e[97m"
#shellcheck disable=SC2034
INFO="\e[102m\e[30m"

K3S_RESOLV_CONF=/etc/rancher/k3s/resolv.conf

echo-head() {
  echo -e "$INFO $@ $RESET $(date)"
}

echo-info() {
  echo -e "$INFO $@ $RESET"
}

echo-warn() {
  echo -e "$WARNING WARN: $@ $RESET" >&2
}

echo-error() {
  echo -e "$ERROR $@ $RESET" >&2
}

#
# Returns zero if the given process id is a child of the ssh daemon
#
# $1 - process id
#
is-ssh-child() {
  currentId=$1
  while [ "$currentId" != "" ] && [ "$currentId" -gt 0 ]; do
    command_and_ppid=$(ps -o comm= -o ppid= "$currentId")
    if [ "$command_and_ppid" != "" ]; then
      # shellcheck disable=SC2086
      set $command_and_ppid
      case $1 in
        *sshd*) return 0 ;;
        *) currentId=$2
      esac
    else
      return 1
    fi
  done
  return 1
}

# Get the home directory of a user
# $1 user
get-home-directory() {
  getent passwd "$1" | cut -d ':' -f6
}

k3s-is-installed() {
  [ "$(systemctl list-unit-files k3s.service | tail -1 | cut -d' ' -f1)" -eq 1 ]
}

k3s-is-running() {
  systemctl -q is-active k3s.service
}

trim-argument() {
  echo "$1" | tr -d "'" | sed s/^=//
}

exit-if-root() {
  if [ "$HOME" = "$(get-home-directory "$(id -un 0)")" ]; then
    echo-error "Using root"
    echo "Please run using sudo from non-root user."
    exit 1
  fi
  if [ "$(id -u)" -ne 0 ]; then
    echo-error "Must be run using sudo"
    exit 1
  fi
}

_tick() {
  : "${TIMEOUT:=900s}"
  : "${DEADLINE:=$(($(date +%s)+${TIMEOUT%s}))}"
  TIMEOUT="$((DEADLINE-$(date +%s)))s"
  if [ 0 -gt "${TIMEOUT%s}" ]; then
    >&2 echo "TIMEOUT EXCEEDED"
    exit 1
  fi
  export TIMEOUT DEADLINE
}

_tick

if [ "$SUDO_USER" != "" ]; then
  HOME="$(get-home-directory "$SUDO_USER")"
  RUNUSER="runuser -p -u $SUDO_USER --"
fi

if ! declare -F _exit > /dev/null; then
  _exit() {
    :
  }
  trap _exit EXIT
fi
