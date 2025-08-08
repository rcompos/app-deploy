#!/usr/bin/env bash

function usage(){
  echo -e "Sync child apps for ArgoCD app-of-apps"
  echo -e "usage: ${0} [-ghiy] [app-of-apps-name]"
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
aoa_name=$1

echo "argocd app sync -l app.kubernetes.io/instance=${aoa_name} ${grpc_web} ${insecure}"

if [ "$noprompt" == false ]; then
  read -p "Sync app-of-apps ${aoa_name} child applications in ArgoCD? [y|n] " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting."
    exit 5
  fi
fi

argocd app sync -l app.kubernetes.io/instance=${aoa_name} ${grpc_web} ${insecure}
