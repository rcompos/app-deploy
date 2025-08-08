#!/usr/bin/env bash

function usage(){
  echo -e "Excecute remote command"
  echo -e "usage: ${0} [-h] [-d] [-e environment] [-t connection_type]  command"
  echo -e "  -h  help"
  echo -e "  -e  environment (default: prod)"
  echo -e "  -t  connection type (default: ssh)"
}

argo_verb="get"
connection_type="ssh"
environment="prod"
debug=0
while getopts "de:ht:" opt; do
  case $opt in
    h) # Handle the -h flag
      usage
      exit 1
      ;;
    d)
      debug=1
      ;;
    e)
      environment="$OPTARG"
      ;;
    t)
      connection_type="$OPTARG"
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
command=$1

declare -A ip_map
if [[ $environment == "prod" ]]; then
  ip_map["az01-sc1"]="10.45.0.2"
  ip_map["az02-sc1"]="10.45.40.13"
  ip_map["az05-sc7"]="10.45.88.133"
  ip_map["az06-sc1"]="10.45.104.3"
  ip_map["az22-sc1"]="10.45.112.2"
  ip_map["az23-sc1"]="10.45.136.2" 
  # ip_map["az23-2-sc1"]="" 
  ip_map["az25-prd1-sc1"]="10.45.168.196" 
  ip_map["az25-prd2-sc1"]="10.45.168.131" 
  # ip_map["az26-sc1"]="" 
  ip_map["az27-sc1"]="10.45.184.147"
  ip_map["az28-sc1"]="10.45.192.74"
  ip_map["az33-sc1"]="10.45.224.133"
  ip_map["az40-sc1"]="10.91.130.2"
  ip_map["az41-sc1"]="10.91.226.2"
  ip_map["az50-sc1"]="10.91.146.2"
  ip_map["az51-sc1"]="10.91.178.2"
  # ip_map["az52-prod1-sc1"]=""
  ip_map["az60-sc1"]="10.91.162.2"
  ip_map["az61-sc1"]="10.91.192.194"
  ip_map["az61-prd2-sc1"]="10.91.195.130"
  # TODO: add more PROD sites
elif [[ $environment == "dev" ]]; then
  ip_map["az24-dev1-sc1"]="10.45.144.170"
  ip_map["az24-cni-sc1"]="10.45.144.26"
  ip_map["az40-dev1-sc1"]="10.91.130.76"
  ip_map["az60-dev1-sc1"]="10.91.161.138"
  # TODO: add more DEV sites
else
  echo "Error: Invalid environment"
  usage
  exit 5
fi

echo "command: $command"

for key in "${!ip_map[@]}"; do
  echo
  # key: node name
  # value: ip address
  site_name=`echo "$key" | awk '{ print tolower ($0) }' | sed 's/-.*//'`
  echo -n "$key [${ip_map[$key]}]"
  echo "  ###############################"

  # site_caps=`echo "$key" | awk '{ print toupper ($0) }'`
  # echo "########################  $site_caps  ##########################"
  # echo

  ### Use Expect script to handle unavoidable prompts
  # echo "./expector.exp $key ${ip_map[$key]} $argo_verb $app_name"
  # ./expector.exp "$key" "${ip_map[$key]}" "$command"

  if [[ $debug -eq 1 ]]; then
    echo "./nke-ssh.sh -d -t $connection_type -n $key -s $site_name -i ${ip_map[$key]} $command"
    ./nke-ssh.sh -d -t "$connection_type" -n "$key" -s "$site_name" -i "${ip_map[$key]}" "$command"
  fi
  ./nke-ssh.sh -t "$connection_type" -n "$key" -s "$site_name" -i "${ip_map[$key]}" "$command"

done