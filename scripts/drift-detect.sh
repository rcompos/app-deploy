#!/usr/bin/env bash
# Gitlab pipeline runs when DETECT_DRIFT=true

ENVIRONMENT=${ENVIRONMENT:-""}  # Environment to compare (optional, default empty string for all)
ENV_NAME=${ENV_NAME:-$ENVIRONMENT}  # Environment to compare (optional, default empty string for all)

BASENAME="drift-detect"
if [ "$ENV_NAME" ]; then
  DEST_BRANCH="${BASENAME}-${ENV_NAME}" # Branch where changes are pushed to
else
  DEST_BRANCH="${BASENAME}-all"
fi
TMP_DIR="${TMP_DIR:-$HOME}"
PROD_TYPE=${PROD_TYPE:-"prod"} # prod or non-prod
CSP=${CSP:-"forge"}            # forge

show_envvars() {
  echo "ENVIRONMENT=${ENVIRONMENT}"
  echo "PROD_TYPE=${PROD_TYPE}"
  echo "CSP=${CSP}"
}

# Function to check for drift and exit if none detected
check_for_drift() {
  git add -A
  git status
  git diff main --exit-code
  if [ $? -eq 0 ]; then
    echo "No drift detected."
    exit 0
  fi
}

# Function to commit and push changes
commit_and_push() {
  local commit_message="$1"
  git commit -m"$commit_message"
  git push --set-upstream origin "$DEST_BRANCH"
}

# Function to handle single environment drift detection
detect_single_environment() {
  local env_name="$1"
  mv "../environments/$PROD_TYPE/$CSP/$env_name" "$TMP_DIR"
  ENV_PATH="${PROD_TYPE}/${CSP}" ./create-app-of-apps-env.sh "$env_name"
  check_for_drift
  commit_and_push "[$env_name] Drift detection pipeline"
}

# Function to handle all environments drift detection
detect_all_environments() {
  mv "../environments/$PROD_TYPE/$CSP" "$TMP_DIR"
  mkdir "../environments/$PROD_TYPE/$CSP"
  for site in `ls -1 "$TMP_DIR/$CSP"`; do
    echo $site
    ENV_PATH="${PROD_TYPE}/${CSP}" ./create-app-of-apps-env.sh "$site"
  done
  check_for_drift
  commit_and_push "[NKE $PROD_TYPE $site] Drift detection pipeline"
}

# Delete existing branch if it exists and is not main
git ls-remote --exit-code --heads origin "$DEST_BRANCH" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  if [ "$DEST_BRANCH" == "main" ]; then
    echo "Forbidden! DEST_BRANCH == main"
    exit 1
  fi
  git push -d origin "$DEST_BRANCH"
fi

show_envvars

# Create new branch
git checkout -b "$DEST_BRANCH"

# Check for drift from templates
if [ "$ENV_NAME" ]; then # Perform actions for single specified environment
  detect_single_environment "$ENV_NAME"
else # Perform actions for all environments
  detect_all_environments
fi

echo "Created branch: $DEST_BRANCH"