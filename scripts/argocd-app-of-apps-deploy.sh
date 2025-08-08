#!/usr/bin/env bash

function usage(){
  echo -e "Deploy ArgoCD app-of-apps Helm chart"
  echo -e "usage: DEPLOY_ENV=name-of-environment ENV_PATH=prod/forge ${0} [-ghiy] [app-of-apps-name]"
  echo -e "  -y  no prompt"
  echo -e "  -g  grpc-web"
  echo -e "  -h  help"
  echo -e "  -i  insecure"
}

noprompt=false
while getopts ghiy arg; do
  case $arg in
    y) # Handle the -y flag
      noprompt=true
      ;;
    h) # Handle the -h flag
      usage
      exit 1
      ;;
    i) # Handle the -i flag
      insecure="--insecure"
      ;;
    g) # Handle the -g flag
      grpc_web="--grpc-web"
      ;;
    \?)
    echo "Error: Invalid options" 
    usage
    exit 2
    ;;
  esac
done
shift $(($OPTIND - 1))
if [[ $# -gt 2 ]]; then
  echo "Error: Too many arguments"
  usage
  exit 3
fi
if [[ $# -lt 1 ]]; then
  echo "Error: One argument required"
  usage
  exit 4
fi

aoa_name=$1
env_dir="environments"

if [[ -z "$DEPLOY_ENV" ]]; then
  echo "Environmental variable DEPLOY_ENV must be defined."
  echo "  export DEPLOY_ENV=nke-site-forge-azNN"
  exit 5
fi
echo "DEPLOY_ENV: ${DEPLOY_ENV}"

default_env_path="prod/forge"
if [[ -z $ENV_PATH ]]; then
  ENV_PATH="$default_env_path"
fi
echo "ENV_PATH: ${ENV_PATH}"

pwd
echo "argocd app create -f ../${env_dir}/${ENV_PATH}/${DEPLOY_ENV}/${aoa_name}/application.yaml ${grpc_web} ${insecure}"

if [ "$noprompt" == false ]; then
  read -p "Create app-of-apps ${aoa_name} in ArgoCD? [y|n] " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting."
    exit 6
  fi
fi

argocd app create -f "../${env_dir}/${ENV_PATH}/${DEPLOY_ENV}/${aoa_name}/application.yaml" ${grpc_web} ${insecure}
