#!/usr/bin/env bash

function usage(){
  echo "Create ArgoCD app-of-apps Helm chart from app-of-apps-chart-templates"
  echo -e "usage: ${0} [-h] [app_of_apps_name]"
  echo -e "  -h  help"
}

force=false
while getopts h arg; do
  case $arg in
    h) # Handle the -h flag
      usage
      exit 1
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
export APP_OF_APPS_NAME=$1

root_dir=$PWD  # scripts directory
template_dir="app-of-apps-chart-templates/v1"

mkdir "../${APP_OF_APPS_NAME}"
if [ $? -ne 0 ]; then
  echo "Error: mkdir ../${APP_OF_APPS_NAME}"
  exit 5
fi
destination_dir="../${APP_OF_APPS_NAME}/v1"

if [ -d "${destination_dir}" ]; then
  echo "App-of-apps Helm chart already exists! ${destination_dir}"
  exit 6
fi

echo "Creating new app-of-apps chart: ${APP_OF_APPS_NAME}"

cp -a "${template_dir}" "${destination_dir}"
if [ ! -d "${destination_dir}" ]; then
  echo "Could not change dir! cp -a ${template_dir} ${destination_dir}"
  exit 7
fi

cd "${destination_dir}"
if [ $? -ne 0 ]; then
  echo "Error: Could change dir: cd ${destination_dir}"
  exit 8
fi
echo "Created directory:"
pwd

for file in `find . -type f`; do
  cat "${file}" | envsubst '${APP_OF_APPS_NAME}' > file.tmp
  mv file.tmp "${file}"
done

mkdir templates
if [ $? -ne 0 ]; then
  echo "Error: Could not create templates dir!"
  exit 9
fi

cd templates
ln -s ../../../scripts/app-generator/v1/templates/app.yaml .

cd "${root_dir}"; echo

if ! command -v tree 1>/dev/null; then
  find "../${APP_OF_APPS_NAME}" -type f
else
  tree "../${APP_OF_APPS_NAME}"
fi

