#!/usr/bin/env bash
# Deploy app-of-apps
# Run scripts to create and sync NKE app-of-apps and child apps
# Must be logged into ArgoCD

function usage(){
  echo -e "Create and sync NKE ArgoCD app-of-apps"
  echo -e "Must be logged into ArgoCD CLI"
  echo -e "usage: ${0} [-hy] [deployment_environment]"
  echo -e "  -h  help"
  echo -e "  -y  no_prompt"
  echo -e "deployment_environment is the env directory under environments"
}

noprompt=false
while getopts "hy" opt; do
  case $opt in
    y) # Handle the -y flag
      noprompt=true
      ;;
    h) # Handle the -h flag
      usage
      exit 1
      ;;
    \?)
    echo "Error: Invalid options" 
    usage
    exit 3
    ;;
  esac
done
shift $(($OPTIND - 1))
if [[ $# -gt 1 ]]; then
  echo "Error: Too many arguments"
  usage
  exit 3
fi
if [[ $# -lt 1 ]]; then
  echo "Error: One argument required"
  usage
  exit 4
fi
export DEPLOY_ENV=$1
echo "DEPLOY_ENV=$DEPLOY_ENV"

default_env_path="prod/forge"
if [[ -z $ENV_PATH ]]; then
  export ENV_PATH="$default_env_path"
fi
echo "ENV_PATH: ${ENV_PATH}"

app_of_apps=("aoa-infra" "aoa-observability" "aoa-nke-site")
echo "App-of-apps:"
for aoa in ${app_of_apps[@]}; do
  echo -e "\t$aoa"
done

if [ "$noprompt" == false ]; then
  read -p "Create and sync app-of-apps in ArgoCD? [y|n] " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting."
    exit 6
  fi
fi
echo

for aoa in ${app_of_apps[@]}; do
  echo $aoa
  echo ./argocd-app-of-apps-deploy.sh -g -i -y "$aoa"
  ./argocd-app-of-apps-deploy.sh -g -i -y "$aoa"
  ### The app-of-apps sync and child-apps sync are deprecated since automated sync was enabled
  # sleep 5
  # echo ./argocd-app-of-apps-sync.sh -g -i -y "$aoa"
  # ./argocd-app-of-apps-sync.sh -g -i -y "$aoa"
  # sleep 5
  # echo argocd app sync -l app.kubernetes.io/instance="$aoa" --async --grpc-web --insecure
  # argocd app sync -l app.kubernetes.io/instance="$aoa" --async --grpc-web --insecure
  # echo
  # sleep 5
done