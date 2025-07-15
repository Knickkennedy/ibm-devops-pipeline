#!/bin/bash

# Check if namespace argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <Namespace>"
    exit 1
fi

NAMESPACE="$1"
VALUES_FILE="devopsplan/backup.yaml"

# Step 1: Check if velero client is installed and install if not
if ! command -v velero &> /dev/null; then
    echo "Velero client not found. Installing Velero client v1.16.0..."
    wget https://github.com/vmware-tanzu/velero/releases/download/v1.16.0/velero-v1.16.0-linux-amd64.tar.gz
    tar -xvf velero-v1.16.0-linux-amd64.tar.gz
    sudo mv velero-v1.16.0-linux-amd64/velero /usr/local/bin/
    rm -rf velero-v1.16.0-linux-amd64 velero-v1.16.0-linux-amd64.tar.gz
    echo "Velero client installed."
fi

echo "Velero client version:"
velero version -n "$NAMESPACE"

# Step 2: Capture the service name and cluster IP for MinIO
MINIO_SERVICE=$(kubectl get svc -n "$NAMESPACE" | awk '/minio/{print $1}')
CLUSTER_IP=$(kubectl get svc -n "$NAMESPACE" | awk '/minio/{print $3}')

if [ -z "$MINIO_SERVICE" ] || [ -z "$CLUSTER_IP" ]; then
    echo "Error: MinIO service not found in namespace $NAMESPACE."
    exit 1
fi

echo "MinIO Service Name: $MINIO_SERVICE"
echo "MinIO Cluster IP: $CLUSTER_IP"

# Step 3: Update /etc/hosts file
HOST_ENTRY="$CLUSTER_IP $MINIO_SERVICE.$NAMESPACE.svc.cluster.local"
if grep -q "$MINIO_SERVICE.$NAMESPACE.svc.cluster.local" /etc/hosts; then
    sudo sed -i "/$MINIO_SERVICE.$NAMESPACE.svc.cluster.local/d" /etc/hosts
fi
echo "$HOST_ENTRY" | sudo tee -a /etc/hosts > /dev/null
echo "Added entry to /etc/hosts: $HOST_ENTRY"

echo "Script execution completed."
