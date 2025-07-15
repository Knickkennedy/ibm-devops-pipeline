#!/bin/bash
#
#################################################################
# Licensed Materials - Property of IBM
# (C) Copyright IBM Corp. 2018.  All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with
# IBM Corp.
#################################################################
#
# You need to run this script for each namespace.
#
# This script takes three arguments:
# the namespace where the chart will be installed
# the initial password for the admin user account
# the MongoDB Connection String URI: https://docs.mongodb.com/manual/reference/connection-string/
# the third argument (mongoConnectionString) is optional.
#
# Example:
#     ./createSecretNamespacePrereqs.sh myNamespace initialPassword mongoConnectionString
#

namespace=$1
initialPassword=$2
mongoConnectionString=${3:-mongodb://user:password@mongo-host:27017}

# Replace the NAMESPACE tag and mongo connection string in a temporary yaml file.
sed -e 's/{{ NAMESPACE }}/'$namespace'/g' -e "s|password: .*|password: ${mongoConnectionString}|" $(dirname $0)/ibm-ucv-prod-databaseSecret.yaml > $(dirname $0)/$namespace-ibm-ucv-prod-databaseSecret.yaml

echo "Adding the Secret for database authentication..."
# add database secret to the namespace
kubectl create -f $(dirname $0)/$namespace-ibm-ucv-prod-databaseSecret.yaml -n $namespace

# Replace the NAMESPACE tag and initialPassword in a temporary yaml file.
sed -e 's/{{ NAMESPACE }}/'$namespace'/g' -e 's/password: admin/password: '$initialPassword'/g' $(dirname $0)/ibm-ucv-prod-initialAdminPasswordSecret.yaml > $(dirname $0)/$namespace-ibm-ucv-prod-initialAdminPasswordSecret.yaml

echo "Adding the Secret for initial admin password..."
# add initial admin secret to the namespace
kubectl create -f $(dirname $0)/$namespace-ibm-ucv-prod-initialAdminPasswordSecret.yaml -n $namespace

# Clean up - delete the temporary yaml file.
rm $(dirname $0)/$namespace-ibm-ucv-prod-initialAdminPasswordSecret.yaml

# Clean up - delete the temporary yaml file.
rm $(dirname $0)/$namespace-ibm-ucv-prod-databaseSecret.yaml
