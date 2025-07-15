#!/bin/bash

# Install local helm repo ChartMuseum, package the helm chart,
# and push to local helm repo.  All this is needed so that we can
# invoke 'oc ibm-pak get caseName...' successfully.

# Install and run ChartMuseum.  The installation script will check to see
# if the chartmuseum executable is already present.
function runChartMuseum()
{
    curl https://raw.githubusercontent.com/helm/chartmuseum/main/scripts/get-chartmuseum | bash
    chartmuseum --debug --port=8080 --storage="local" --storage-local-rootdir="./chartstorage" > chartmuseum.out 2>&1 &
    CHARTMUSEUM_PID=$!
}

# Create helm package and push it to the ChartMuseum chart repo
function pkgAndPushChart()
{
    rm -rf ./pkgdir
    helm package ${CV_TEST_BUNDLE_DIR}/charts/ibm-ucd* -d pkgdir
    PKGNAME="@$(echo pkgdir/*)"
    curl --data-binary "$PKGNAME" http://localhost:8080/api/charts
}


