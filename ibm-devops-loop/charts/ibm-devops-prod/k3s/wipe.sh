#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../lib/cli.sh"

if [ "--confirm" != "$1" ] || [ "$(id -u)" -ne 0 ]; then
   echo-error "Must be run using sudo $0 --confirm"
   echo-error "DATA LOSS will occur!"
   exit 1;
fi

echo-info wipe k3s
if [ -x /usr/local/bin/k3s-uninstall.sh ]; then
  /usr/local/bin/k3s-uninstall.sh
  rm -fr /etc/rancher || true
fi

echo-info wipe /var/lib files
rm -fr /var/lib/kubelet || true

echo-info wipe executables
rm -f /usr/local/bin/kubectl || true

echo-info wipe home files from $HOME
rm -fr "$HOME/.kube" || true

if command -v firewall-cmd >/dev/null && [ "running" = "$(firewall-cmd --state 2>/dev/null)" ]; then
  echo-info remove firewall-cmd rules
  firewall-cmd -q --remove-service=http --remove-service=https --permanent
  firewall-cmd -q --zone=trusted --remove-interface=cni0 --permanent
  firewall-cmd -q --reload
fi
