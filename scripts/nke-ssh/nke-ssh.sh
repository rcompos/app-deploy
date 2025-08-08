#!/usr/bin/env bash
# Run command for all sites

function usage(){
  echo -e "Run command on specified site controller instance"
  echo -e "usage: ${0} [-h] [-d] [-t connection_type] [-i ip_addr] [-k port_kube] [-a port_argo] [-n node_name] [-s site_name] command"
  echo -e "  -h  help"
  echo -e "  -d  debug"
  echo -e "  -i  ip address"
  echo -e "  -k  local kubernetes port (default 6445)"
  echo -e "  -a  local argocd port (default 8443)"
  echo -e "  -s  site name"
  echo -e "  -n  node name"
  echo -e "  -t  connection type"
}

port_kube=6445
port_argo=8443
debug=0
connection_type="ssh"
while getopts "a:dhi:k:n:s:t:" opt; do
  case $opt in
    h) # Handle the -h flag
      usage
      exit 1
      ;;
    d) # Handle the -d flag
      debug=1
      ;;
    a)
      port_argo="$OPTARG"
      ;;
    i)
      ip_addr="$OPTARG"
      ;;
    k)
      port_kube="$OPTARG"
      ;;
    n)
      node_name="$OPTARG"
      ;;
    s)
      site_name="$OPTARG"
      ;;
    t)
      connection_type="$OPTARG"
      ;;
    \?)
      echo "Error: Invalid options" 
      usage
      exit 3
      ;;
  esac
done
shift $(($OPTIND - 1))
# echo "Number of args: $#"
if [[ $# -gt 1 ]]; then
  echo "Error: Too many arguments"
  usage
  exit 4
fi
if [[ $# -lt 1 ]]; then
  echo "Error: One arguments required"
  usage
  exit 5
fi
command=$1

if [[ $debug -eq 1 ]]; then
  echo "site_name: $site_name" >&2
  echo "node_name: $node_name" >&2
  echo "ip_addr:   $ip_addr" >&2
  echo "port_kube: $port_kube" >&2
  echo "port_argo: $port_argo" >&2
  echo "command:   $command" >&2
  echo "connection_type:   $connection_type" >&2
  echo "debug: $debug" >&2
fi

trap 'catch $? $LINENO' ERR

catch() {
    echo "Error $1 occurred on $2"
    kill %%
    kill %%
}

ssh_tunnel_kubernetes() {
    # SSH tunnel for kubernetes api
    listeners=`netstat -an | grep $port_kube | grep LISTEN | wc -l | awk '{$1=$1};1'`
    if [ "$listeners" -ne 0 ]; then
      kube_listeners=`netstat -an | grep "$port_kube"`
      echo "Listeners already on port ${port_kube}! Shut them down and retry."
      echo "$kube_listeners"
      exit 1
    fi  
    echo "ssh -q -N -L ${port_kube}:${ip_addr}:6443 ${node_name} &"
    ssh -q -N -L "${port_kube}:${ip_addr}:6443" "${node_name}" &
    # You must enter password manually if not running under expect script
    SSH_PID=$!
    sleep 15
    export KUBECONFIG="$HOME/.kube/nke-site-forge-${site_name}.kubeconfig"
    echo "KUBECONFIG: $KUBECONFIG"
}

kill_ssh_tunnel_kubernetes() {
    # Clean-up
    echo kill $SSH_PID
    kill $SSH_PID
    # jobs
}

forward_argocd() {
    # ArgoCD port-forward
    ARGOCD_PW=`argocd admin initial-password -n argocd | head -1`
    echo "ARGOCD_PW: *****"
    echo "kubectl -n argocd port-forward service/argocd-server ${port_argo}:443 &"
    kubectl -n argocd port-forward service/argocd-server "${port_argo}:443" &
    PORT_FORWARD_PID=$!
    sleep 10 

    # ArgoCD authentication
    echo "argocd login localhost:${port_argo} --username admin --password ***** --insecure"
    argocd login "localhost:${port_argo}" --username admin --password $ARGOCD_PW --insecure
}

kill_argocd_tunnel() {
    # jobs
    echo kill $PORT_FORWARD_PID
    kill $PORT_FORWARD_PID
    sleep 5
}

run_ssh_command() {
  if [[ $debug -eq 1 ]]; then
    echo "ssh -v ${node_name} $command"
    ssh -v "${node_name}" "$command"
  else
    ssh -q "${node_name}" "$command"
  fi
}

if [[ $connection_type == "ssh" ]]; then
  run_ssh_command  
elif [[ $connection_type == "kubernetes" ]]; then
  ssh_tunnel_kubernetes

  # Debug
  echo "kubectl get no"
  kubectl get no

  kill_ssh_tunnel_kubernetes
elif [[ $connection_type == "argocd" ]]; then
  ssh_tunnel_kubernetes
  forward_argocd

  # Debug
  echo "argocd app list"
  argocd app list

  kill_argocd_tunnel
  kill_ssh_tunnel_kubernetes
fi
