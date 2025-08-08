#!/bin/bash

# Usage function
usage() {
  echo "This is a helper script to add/update vault policies for NKE sites in ngcsecurity/insfrastructure-live repo"
  echo "Use this script to onboard/update vault config for sites and open MRs in the repo for config to be applied"
  echo "NOTE - this script relies on a SOURCE_SITE from which we copy the files. Always make sure to use an upto date SOURCE_SITE"
  echo "NOTE - Run this script from root of ngcsecurity/insfrastructure-live repo"
  echo "Usage: $0 --mode <add|update> --source-site <name> --destination-site <name>"
  echo "UPDATE Example: nke-site-deploy/scripts/vault-config-mr-helper.sh --mode update --source-site nke-site-forge-az24 --destination-site nke-site-forge-az60-dev"
  echo "ADD Example: nke-site-deploy/scripts/vault-config-mr-helper.sh --mode update --source-site nke-site-forge-az24 --destination-site nke-site-forge-azxy"
  exit 1
}

# Trim function
trim() {
  local var="$1"
  # Remove leading whitespace
  var="${var#"${var%%[![:space:]]*}"}"
  # Remove trailing whitespace
  var="${var%"${var##*[![:space:]]}"}"
  echo "$var"
}

# Initialize variables
MODE=""
SOURCE_SITE=""
DESTINATION_SITE=""

# Parse named arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE=$(trim "$2")
      shift 2
      ;;
    --source-site)
      SOURCE_SITE=$(trim "$2")
      shift 2
      ;;
    --destination-site)
      DESTINATION_SITE=$(trim "$2")
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Debug: Uncomment to see what was parsed
# echo "MODE='$MODE'"
# echo "SOURCE_SITE='$SOURCE_SITE'"
# echo "DESTINATION_SITE='$DESTINATION_SITE'"


# Validate required arguments
if [[ -z "$MODE" || -z "$SOURCE_SITE" || -z "$DESTINATION_SITE" ]]; then
  echo "Error: All arguments are required."
  usage
fi

if [[ "$MODE" != "add" && "$MODE" != "update" ]]; then
  echo "Error: --mode must be 'add' or 'update'."
  usage
fi

BASE_PATH=./vault/prod/ngc/nkek8s

EXCLUDE_FILES=(
  ".terraform.lock.hcl"
)

EMPTY_FILES=(
  "jwt-pubkey"
)

src_dir="${BASE_PATH}/${SOURCE_SITE}"
dst_dir="${BASE_PATH}/${DESTINATION_SITE}"

mkdir -p "$dst_dir"

EXCLUDE_OPTS=()
for file in "${EXCLUDE_FILES[@]}"; do
  EXCLUDE_OPTS+=(--exclude="$file")
done

if [[ "$MODE" == "update" ]]; then
  for file in "${EMPTY_FILES[@]}"; do
    EXCLUDE_OPTS+=(--exclude="$file")
  done
fi

rsync -a "${EXCLUDE_OPTS[@]}" "${src_dir}/" "$dst_dir/"

if [[ "$MODE" == "add" ]]; then
  for empty_file in "${EMPTY_FILES[@]}"; do
    find "$dst_dir" -type f -name "$empty_file" -exec truncate -s 0 {} +
  done
fi

find "$dst_dir" -type f -exec sed -i '' \
  -e "s/${SOURCE_SITE}/${DESTINATION_SITE}/g" {} +


echo "Site $DESTINATION_SITE processed in $MODE mode."