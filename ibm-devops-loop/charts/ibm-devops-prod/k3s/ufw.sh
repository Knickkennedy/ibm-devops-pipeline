#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../lib/cli.sh"

echo -e "$BRAND Configure UFW firewall Rules$RESET"

exit-if-root

if ! command -v ufw; then
  echo-error "ufw is not installed"
  echo "This script configures rules for Uncomplicated Firewall (ufw), however it does not appear"
  echo "to be installed."
  exit 1
fi

if ufw status | grep -q "Status: active"; then
  while true; do
    echo "UFW is running, please confirm that you want to make changes to the rules."
    echo -n "(c)ontinue, (a)bort: "
    read -r opt
    if [ "$opt" = "a" ] || [ "$opt" = "A" ]; then
      exit 1
    elif [ "$opt" = "c" ] || [ "$opt" = "C" ]; then
      break
    fi
  done
fi

# Must allow traffic on the cni0 interface
ufw allow in on cni0
ufw allow out on cni0
ufw route allow in on cni0 out on cni0

if ufw show added | grep -q -w "22"; then
  echo-info "Existing rule for ssh"
  echo "It appears that you already have rules for ssh configured:"
  ufw show added | grep -w "22" | while read -r line; do
    echo "  $line"
  done
  echo "Not adding one"
else
  ufw allow ssh
fi

if ufw show added | grep -q -w "443"; then
  echo-info "Existing rule for https"
  echo "It appears that you already have rules for https configured:"
  ufw show added | grep -w "443" | while read -r line; do
    echo "  $line"
  done
  echo "Not adding one"
else
  ufw allow https
fi


echo-info "UFW rules configured"
if ufw status | grep -q "Status: inactive"; then
  echo "The firewall is not running, it can be started with:"
  echo
  echo "  sudo ufw enable"
fi
