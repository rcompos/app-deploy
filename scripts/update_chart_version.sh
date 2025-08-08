#!/usr/bin/env sh
# Update Helm chart Chart.yaml
# First argument is path to directory where Chart.yaml exists
# Second argument is the appVersion
# Performs the following two steps:
# 1. Iterate version by adding 1
# 2. Set appVersion to passed in argument

function usage(){
  echo -e "usage: ${0} [path_to_chart_dir] [commit_sha]\n"
}

if [ $# -gt 2 ] || [ $# -lt 2 ] ||  [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit
fi

CHART_DIR=$1
CI_COMMIT_SHA=$2

#echo "CHART_DIR: $CHART_DIR"
#echo "CI_COMMIT_SHA: $CI_COMMIT_SHA"

echo "Set Helm chart version and appVersion"
perl -pi -e 's/^version:\s*(.*\.)([0-9]+)/version: $1${\($2+1)}/' ${CHART_DIR}/Chart.yaml
perl -pi -e "s/^\s*appVersion:\s*\S*/appVersion: \"${CI_COMMIT_SHA}\"/" ${CHART_DIR}/Chart.yaml
# egrep "^version:|^appVersion:" ${CHART_DIR}/Chart.yaml
# grep "repository:" ${CHART_DIR}/values.yaml
