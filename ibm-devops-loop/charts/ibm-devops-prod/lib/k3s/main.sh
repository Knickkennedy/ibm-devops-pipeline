#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../cli.sh"

PRODUCT_NAME="DevOps Test Hub"
PRODUCT_VERSION=11.0.5

K8S_VERSION=1.32.4
K3S_VERSION=k3s1
K3S_IMAGE_DIR=/var/lib/rancher/k3s/agent/images

: "${IMAGE_REGISTRY:=cp.icr.io/cp}"

K3S_START_TIME="$(date -u '+%Y-%m-%d %H:%M:%S')"

_exit() {
  journalctl -p err --since "$K3S_START_TIME"
  echo
  echo-error 'INSTALL FAILED'
}

# Check that INGRESS_DOMAIN can be resolved in the cluster, if it hasn't been
# set attempt to find an appropriate value.
_test_ingress_domain() {
  local status
  [ "$SKIP_DNS_TEST" = true ] || _test_ingress_domain_pod
  status=$?
  _delete_util_pod_now
  return $status
}

_test_ingress_domain_pod() {
  if [ "$INGRESS_DOMAIN" = "" ]; then
    # helm will error if the hostname has upper-case letters anywhere
    # so convert all to lower-case.
    INGRESS_DOMAIN="$(hostname -f | tr '[:upper:]' '[:lower:]')"
    _test_dns_name "wildcard.$INGRESS_DOMAIN" && return 0
    INGRESS_DOMAIN="$(ip route get "$(ip route show 0.0.0.0/0 | grep -oP 'via \K\S+')" | grep -oP 'src \K\S+').nip.io"
  fi
  _test_dns_name "wildcard.$INGRESS_DOMAIN"
}

# $1 - retries
# $2 - sleep duration
_test_pod_creation() {
  local podName
  local ret
  local retries
  local sleepDuration

  if [ "$_CLI_FUNCS_UTIL_POD_NAME" != "" ]; then
    $RUNUSER kubectl get pod "$_CLI_FUNCS_UTIL_POD_NAME" > /dev/null 2>&1
    return $?
  fi

  retries="$1"
  sleepDuration="$2"
  ret=1
  podName=util-pod-$(date -u +%Y%m%d%H%M%S)

  _CLI_FUNCS_UTIL_POD_NAME="$podName"
  _delete_util_pod_later

  echo "Creating Pod: $podName"
  # Leaving the pod running for an hour (sleep 3600) should be more than enough
  # for our purposes
  if $RUNUSER kubectl run "$podName" --restart=Never --image=docker.io/rancher/mirrored-library-busybox:1.36.1 \
	  -- sh -c 'sleep 3600' > /dev/null; then
    while [ "$retries" -gt 0 ]; do
      local status
      local state
      local reason
      set -- $($RUNUSER kubectl describe pod "$podName" | \
        grep -e "Status:\|State:\|Reason:" | sed 's/.*://g')
      # This dependent on the order of fields returned by
      # $RUNUSER kubectl describe
      status="$1"
      state="$2"
      reason="$3"

      echo "  [$status] $state $reason"
      case "$state" in
        Terminated)
          break
          ;;
        Waiting)
          if [ "$reason" = "ImagePullBackOff" ]; then
            break
          fi
          ;;
	Running)
	  ret=0
	  break
	  ;;
      esac
      retries=$(("$retries" - 1))
      if [ "$retries" -gt 0 ]; then
        sleep "$sleepDuration"
      fi
    done
    if [ "$ret" -ne 0 ]; then
      $RUNUSER kubectl get pod "$podName" -owide
      $RUNUSER kubectl describe pod "$podName" | \
        awk 'BEGIN {show=0} /^Events:/ {show=1} /.*/ { if(show==1) print $0 }'
      $RUNUSER kubectl logs "$podName"
    fi
  fi
  if [ "$ret" -ne 0 ]; then
    echo-error "Pod failed to start"
  fi

  return $ret
}

#
# Confirm that the given name can be resolved within the cluster.
#
# $1 - hostname to verify
#
# return:
#     0 if hostname can be resolved
#     1 (or at least non-zero) if hostname cannot be resolved
#
_test_dns_name() {
  if ! _test_pod_creation 30 10; then
    return 1;
  fi

  echo "Testing DNS resolution of: $1"
  $RUNUSER kubectl exec "$_CLI_FUNCS_UTIL_POD_NAME" -- nslookup "$1" >/dev/null 2>&1
}

_delete_util_pod() {
  if [ "$_CLI_FUNCS_UTIL_POD_NAME" != "" ]; then
    $RUNUSER kubectl delete pod "$_CLI_FUNCS_UTIL_POD_NAME" --now
  fi
  unset _CLI_FUNCS_UTIL_POD_NAME
}

_delete_util_pod_now() {
  trap _exit EXIT
  _delete_util_pod
}

_delete_util_pod_later() {
  trap '_delete_util_pod; _exit' EXIT
}

_wait_for_nodes_ready() {
  while $RUNUSER kubectl get node --no-headers | grep -v '\bReady\b'; do
   echo "WARNING: Nodes aren't ready, waiting to see if they self correct"
   _tick
   sleep 23
  done
}

_kube_wait_for() {
  NEXT_WAIT_TIME=0
  while true; do
    if _kube_has "$@"; then
      return 0;
    elif [ $NEXT_WAIT_TIME -eq 25 ]; then
      return 1;
    else
      sleep $(( NEXT_WAIT_TIME++ ))
    fi
  done
}

_kube_has() {
  local type="$1"
  shift
  case $type in
    pod-count*)
      [ "$($RUNUSER kubectl get pods -n "$1" -oname | wc -l)" -ge "$2" ]
    ;;
    pod*)
      $RUNUSER kubectl get pods "$@" 2>/dev/null | grep -c -E ' ([0-9]+)/\1 +Running' | grep -q '^1$'
    ;;
    crd*)
      local count="$1"
      shift
      $RUNUSER kubectl get crds 2>/dev/null | "$@" | grep -q "^$count$"
    ;;
    secret*)
      $RUNUSER kubectl get secret "$@" > /dev/null 2>&1
    ;;
    *)
      echo unknown resource type "$type" >&2
      return 1
    ;;
  esac
}

_ensure_k3s_is_running() {
  if ! k3s-is-running; then
     echo-error "it looks as if k3s is installed, but not running"
     echo "Either restart using:"
     echo "  sudo systemctl start k3s"
     echo "Or remove using:"
     echo "  k3s-uninstall.sh"
     exit 1
  fi
}

_test_kubectl_executable() {
  [ ! -f /usr/local/bin/kubectl ] || [ "$(readlink -f /usr/local/bin/kubectl)" == "/usr/local/bin/k3s" ]
}

# $1 - client or server
_k3s_version() {
  $RUNUSER kubectl version | sed -n "s/$1[[:space:]]Version:[[:space:]]\(.*\)/\1/p"
}

# $1 - Client or Server
_test_k3s_version() {
  [ "$(_k3s_version "$1")" = "v$K8S_VERSION+$K3S_VERSION" ]
}

_ensure_k3s_version() {
  if ! _test_k3s_version Client ||  ! _test_k3s_version Server; then
    echo-error "k3s is installed but at the wrong version"
    echo "Client: $(_k3s_version Client)"
    echo "Server: $(_k3s_version Server)"
    echo "Require version: v$K8S_VERSION+$K3S_VERSION"
    echo "Please uninstall using:"
    echo "  k3s-uninstall.sh"
    if [ -f k3s ] || [ -f install.sh ] || [ -f k3s-airgap-images-amd64.tar ]; then
      echo "Then rerun this script, additionally specifying the --overwrite-k3s-files flag"
    else
      echo "Then rerun this script"
    fi
    exit 1
  fi
}

echo -e "$BRAND $PRODUCT_NAME v$PRODUCT_VERSION $RESET $0"
echo Initialization time varies but in typical conditions takes 10 minutes

PATH=$PATH:/usr/local/bin # workaround sudo secure path

exit-if-root

if [ "$SKIP_SSH_TEST" != true ] && ! is-ssh-child $PPID; then
  echo-warn "You do not appear to be running in an ssh session.  This could be because you"
  echo-warn "are running in a desktop environment, which is not advised."
  while true; do
    read -p "Do you wish to continue (y/n) " opt
    case $opt in
      y|Y) break;;
      n|N) exit 1;;
    esac
  done
fi

if snap list microk8s >/dev/null 2>&1; then
  echo-error "microk8s is installed"
  echo "This script installs a k3s-based Kubernetes environment, the microk8s snap should be"
  echo "removed before running it.  This can be done with the following command:"
  echo "  sudo snap remove microk8s --purge"
  if [ -f "$HOME/.kube/config" ]; then
    echo
    echo "You should also remove old Kubernetes configuration:"
    echo "  rm $HOME/.kube.config"
  fi
  if ! _test_kubectl_executable; then
    echo
    echo "You should also remove the existing kubectl:"
    echo "  sudo rm /usr/local/bin/kubectl"
  fi
  exit 1
fi

if snap list helm >/dev/null 2>&1; then
  echo-error "helm snap is installed"
  echo "The helm snap must be removed.  This can be done with the following command:"
  echo "  sudo snap remove helm --purge; exit"
  echo "Then install is using:"
  echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | sudo bash"
  exit 1
fi

if ! _test_kubectl_executable; then
  echo-error "incorrect kubectl installed"
  echo "You have a version of kubectl that is not linked to k3s, please remove:"
  echo "  sudo rm /usr/local/bin/kubectl"
  exit 1
fi

case "$(command -v kubectl)" in
  ""|"/usr/local/bin/kubectl") ;;
  *) echo-error "unexpected version of kubectl installed"
     echo "Please remove: $(command -v kubectl)"
     exit 1
esac

#swapoff
if ! free | grep -q 'Swap: *0 *0 *0'; then
  echo Disable swap...
  swapoff -a || true
#ignore errors currently because of WSL2
  sed -i -e 's/^[^#].* none  *swap /#&/' /etc/fstab
fi

# Increase max_user_watches if necessary
if [ "$(cat /proc/sys/fs/inotify/max_user_watches)" -lt 65536 ]; then
  echo "Increasing max_user_watches to 65536"
  echo "fs.inotify.max_user_watches=65536" | tee -a /etc/sysctl.conf > /dev/null && sysctl -p
fi
if [ "$(cat /proc/sys/fs/inotify/max_user_instances)" -lt 512 ]; then
  echo "Increasing max_user_instances to 512"
  echo "fs.inotify.max_user_instances=512" | tee -a /etc/sysctl.conf > /dev/null && sysctl -p
fi

if ! bash "$(dirname "${BASH_SOURCE[0]}")/dns.sh"; then
  echo-error "could not configure DNS"
  exit 1
fi

# install k3s
echo-head k3s
if k3s-is-installed; then
  _ensure_k3s_is_running
  _ensure_k3s_version
else
  if [ -f "$HOME/.kube/config" ]; then
      echo "Kubernetes config already exists. Wipe $HOME/.kube/config"
      exit 1
  fi

  mkdir -p "$K3S_IMAGE_DIR"
  shopt -s nullglob
  for file in k3s-airgap-images-amd64.tar*
  do
    cp "$file" "$K3S_IMAGE_DIR"
  done

  if [ -z "$REGISTRY_MIRRORS" ] && [ -n "$DOCKER_REGISTRY" ]; then
    REGISTRY_MIRRORS="docker.io=https://$DOCKER_REGISTRY"
  fi

  if [ -n "$REGISTRY_MIRRORS" ] || [ -n "$IMAGE_REGISTRY_PASSWORD" ]; then
    mkdir -p /etc/rancher/k3s
    rm /etc/rancher/k3s/registries.yaml 2>/dev/null || true
    if [ -n "$REGISTRY_MIRRORS" ]; then
      echo mirrors: >> /etc/rancher/k3s/registries.yaml
      for m in $REGISTRY_MIRRORS; do
      cat << EOF >> /etc/rancher/k3s/registries.yaml
  ${m%%=*}:
    endpoint:
      - ${m#*=}
EOF
      done
    fi
    if [ -n "$IMAGE_REGISTRY_PASSWORD" ]; then
      cat << EOF >> /etc/rancher/k3s/registries.yaml
configs:
  ${IMAGE_REGISTRY/%\/*/}:
    auth:
      username: ${IMAGE_REGISTRY_USERNAME-cp}
      password: ${IMAGE_REGISTRY_PASSWORD}
EOF
    fi
  fi

  CACHE_K3S_DIR="$HOME/.cache/k3s-${K8S_VERSION}+$K3S_VERSION"
  $RUNUSER mkdir -p "$CACHE_K3S_DIR"

  if [ "$OVERWRITE_K3S_FILES" == "true" ] || [ ! -s "$CACHE_K3S_DIR/k3s" ]; then
    echo Fetch k3s...
    $RUNUSER curl -f -o "$CACHE_K3S_DIR/k3s" -L \
      https://github.com/k3s-io/k3s/releases/download/v${K8S_VERSION}%2B$K3S_VERSION/k3s
  fi
  if [ "$OVERWRITE_K3S_FILES" == "true" ] || [ ! -s "$CACHE_K3S_DIR/install.sh" ]; then
    $RUNUSER curl -f -o "$CACHE_K3S_DIR/install.sh" -L https://get.k3s.io
    chmod +x "$CACHE_K3S_DIR/install.sh"
  fi

  install "$CACHE_K3S_DIR/k3s" /usr/local/bin/

  INSTALL_K3S_SKIP_DOWNLOAD=binary K3S_KUBECONFIG_MODE="644" "$CACHE_K3S_DIR/install.sh" \
    --disable=traefik \
    --resolv-conf="$K3S_RESOLV_CONF" \
    $K3S_INSTALL_EXTRA_ARGS

  mkdir -p "$HOME/.kube" || true
  cp /etc/rancher/k3s/k3s.yaml "$HOME"/.kube/config
  chown -R "$SUDO_USER:" "$HOME/.kube"
  chmod 600 "$HOME/.kube/config"

  _ensure_k3s_version

  if command -v firewall-cmd >/dev/null && [ "running" = "$(firewall-cmd --state 2>/dev/null)" ]; then
    firewall-cmd -q --zone=trusted --add-interface=cni0 --permanent
    firewall-cmd -q --reload
  fi

  if ! [ -d /var/lib/rancher/k3s/server/manifests ]; then
    echo -n "Waiting on k3s to create /var/lib/rancher/k3s/server/manifests"
    while ! [ -d /var/lib/rancher/k3s/server/manifests ]; do
      echo -n .
      sleep 1
    done
    echo
  fi

  echo "Waiting for core Kubernetes pods to start..."

  if ! _kube_wait_for pod-count kube-system 3; then
    echo-error "Core Kubernetes pods not starting"
    exit 1
  fi

  for pod in $($RUNUSER kubectl get pods -oname -n kube-system | grep -v install); do
    echo "Waiting for $pod to become ready..."
    if ! _kube_wait_for pod -n kube-system "$(echo "$pod" | cut -d '/' -f2)"; then
      echo-error "$pod did not start"
      exit 1
    fi
  done

  if ! _test_pod_creation 30 10; then echo
    echo "Could not create a pod in the cluster, please confirm that k3s is running correctly then re-run this script."
    exit 1
  fi
fi

if ! _test_ingress_domain; then
  echo-error "Failed to validate INGRESS_DOMAIN: $INGRESS_DOMAIN"
  echo-error "Set environment variable SKIP_DNS_TEST=true to skip validation."
  exit 1
fi

# inject ingress domain into hosts to enable loopback should there be a firewall or dns issue
touch /var/lib/rancher/k3s/server/manifests/coredns.yaml.skip
sed -E "/#devops-ingress/d; s/^( *)hosts .*/\0\n\1  $( \
  $RUNUSER kubectl get cm coredns -ojsonpath='{.data.NodeHosts}' -n kube-system | head -n1 \
  ) $INGRESS_DOMAIN #devops-ingress/" \
  /var/lib/rancher/k3s/server/manifests/coredns.yaml > /var/lib/rancher/k3s/server/manifests/custom-coredns.yaml

if command -v ufw >/dev/null; then
  echo-head Firewall
  echo "You should configure a firewall that allows at least traffic on cni0 and port 443."
  echo "An example Uncomplicated Firewall (ufw) configuration script can be found here:"
  echo "  $(realpath "$(dirname "${BASH_SOURCE[0]}")/../k3s/ufw.sh")"
  echo "Consult your network administrator on whether it is sufficient for your corporate policy."
fi

_exit() {
  :
}
