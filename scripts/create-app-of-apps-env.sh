#!/usr/bin/env bash

function usage(){
  echo "Construct environmental directory for new cluster."
  echo "Specify the name of the environment to create under directory environments"
  echo -e "usage: ${0} [-h] [-v version] environment_name"
  echo -e "  -h  help"
  echo -e "  -v  template version"
  echo -e " Optional:"
  echo -e "   Set PROD_TYPE as prod or non-prod (default: prod)"
  echo -e "   Set CSP as cloud service provider (default: forge)"
  echo -e "   Set TARGET_REVISION as app-of-apps git target revision (default: main)"
}

template_dir="../environment-templates/nke-site-forge"
force=false
target_version=v1
while getopts hv: arg; do
  case $arg in
    h) # Handle the -h flag
      usage
      exit 1
      ;;
    v) # Handle the -v flag
      target_version="$OPTARG"
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
  echo "Error: Must supply single argument"
  usage
  exit 3
fi
export ENV_NAME=$1
export REPO_URL="https://gitlab.com/nvidia/nvcloud/gitlab_nke-site-deploy.git"
export ENV_DIR="environments"

default_prod_type="prod"
if [[ -z $PROD_TYPE ]]; then
  export PROD_TYPE="$default_prod_type"
fi
echo "PROD_TYPE: ${PROD_TYPE}"

default_csp="forge"
if [[ -z $CSP ]]; then
  export CSP="forge"
fi
echo "CSP: ${CSP}"

default_target_revision="main"
if [[ -z $TARGET_REVISION ]]; then
  export TARGET_REVISION="$default_target_revision"
fi
echo "TARGET_REVISION: ${TARGET_REVISION}"

root_dir=$PWD  # scripts directory
if [ ! -d "../${ENV_DIR}" ]; then
  echo "Creating environment directory! ../${ENV_DIR}"
  mkdir "../${ENV_DIR}"
fi

environment_dir="../${ENV_DIR}/${PROD_TYPE}/${CSP}/${ENV_NAME}"
# Set PATH_TO_APP_OF_APPS to override default chart location (..)
if [ -d "${environment_dir}" ]; then
  echo "Environment directory already exist! ${environment_dir}"
  exit 5
fi

echo "Creating new environment directory: ${ENV_NAME}"
cp -a "${template_dir}" "${environment_dir}"
if [ $? -ne 0 ]; then
  echo "Error: Could not copy dir: cp -a ${template_dir} ${environment_dir}"
  exit 9
fi

cd "${environment_dir}"
if [ $? -ne 0 ]; then
  echo "Error: Could change dir: cd ${environment_dir}"
  exit 9
fi
echo "Created directory:"
pwd

for file in `find . -type f`; do
  cat ${file} | envsubst '$ENV_DIR $ENV_NAME $REPO_URL $PROD_TYPE $CSP $TARGET_REVISION' > file.tmp
  mv file.tmp ${file}
done

cd $root_dir; echo
if ! command -v tree 1>/dev/null; then
  find "${environment_dir}" -type f
else
  tree "${environment_dir}"
fi
