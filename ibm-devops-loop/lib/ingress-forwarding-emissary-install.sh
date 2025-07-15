#!/bin/bash

DEPLOY_WSS_INTERNAL_PORT=7919
CONTROL_SSH_INTERNAL_PORT=9022
DEPLOY_WSS_EXTERNAL_PORT=${DEPLOY_WSS_INTERNAL_PORT}
CONTROL_SSH_EXTERNAL_PORT=${CONTROL_SSH_INTERNAL_PORT}

# Add the Repo:
helm repo add datawire https://app.getambassador.io
helm repo update
 
# Create Namespace and Install:
kubectl create namespace emissary && \
kubectl apply -f https://app.getambassador.io/yaml/emissary/3.9.1/emissary-crds.yaml
 
kubectl wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system

cat <<EOF > emissary-ports.yaml
service:
  ports:
    - name: http-forward
      port: 80 
      targetPort: 8080
      #nodePort: <optional>
    - name: deploy-wss
      port: ${DEPLOY_WSS_EXTERNAL_PORT}
      targetPort: ${DEPLOY_WSS_INTERNAL_PORT}
      #nodePort: <optional>
    - name: control-ssh
      port: ${CONTROL_SSH_EXTERNAL_PORT}
      targetPort: ${CONTROL_SSH_INTERNAL_PORT}
      #nodePort: <optional>
EOF

helm install emissary-ingress --namespace emissary datawire/emissary-ingress -f emissary-ports.yaml && \
kubectl -n emissary wait --for condition=available --timeout=90s deploy -lapp.kubernetes.io/instance=emissary-ingress && \
echo '\n\nOn IKS: export SERVICE_IP=$(kubectl get svc --namespace emissary emissary-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')'


