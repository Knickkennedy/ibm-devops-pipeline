#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../lib/cli.sh"

if [ -n "$WIPE" ]; then
  "$(dirname "${BASH_SOURCE[0]}")/wipe.sh" $WIPE
fi

. "$(dirname "${BASH_SOURCE[0]}")/../lib/k8s.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../lib/ingress/main.sh"

echo
echo "The following configuration was used:"
echo "   INGRESS_DOMAIN=$INGRESS_DOMAIN"

if [ $# -gt 0 ]; then
  _wait_for_nodes_ready

  CHART_HOME="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"

  echo-info 'Helm install'
  echo "helm upgrade ${HELM_NAME:-main} --install $CHART_HOME \\"
  echo "  --timeout $TIMEOUT \\"
  echo "  --create-namespace \\"
  echo "  -f $CHART_HOME/values-k3s.yaml \\"
  echo "  --set global.domain=$INGRESS_DOMAIN \\"
  echo "  $@"

  $RUNUSER helm upgrade "${HELM_NAME:-main}" --install "$CHART_HOME" \
    --timeout "$TIMEOUT" \
    --create-namespace \
    -f "$CHART_HOME/values-k3s.yaml" \
    --set global.domain="$INGRESS_DOMAIN" \
    "$@"
else
  echo-warn Skipped install of chart due to no extra options being given.
fi

echo
echo "INSTALL COMPLETED SUCCESSFULLY"
