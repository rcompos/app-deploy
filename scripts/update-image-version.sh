#!/usr/bin/env bash
# update-image-version.sh
# Usage: ./update-image-version.sh <prod|non-prod> <app-name> <new-version>
# Examples:
# ./scripts/update-image-version.sh prod cloud-workflow-engine v0.0.<new-version>
# ./scripts/update-image-version.sh prod site-workflow-engine v0.0.<new-version>  

ENV_TYPE=$1
APP_NAME=$2
NEW_VERSION=$3

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <prod|non-prod> <app-name> <new-version>"
    echo "Examples:"
    echo "  ./scripts/update-image-version.sh prod cloud-workflow-engine v0.0.<new-version>"
    echo "  ./scripts/update-image-version.sh prod site-workflow-engine v0.0.<new-version>"
    exit 1
fi

if [[ "$ENV_TYPE" != "prod" && "$ENV_TYPE" != "non-prod" ]]; then
    echo "Error: Environment type must be 'prod' or 'non-prod'"
    exit 1
fi

update_version_in_file() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        if grep -q "tag:" "$file"; then
            # cloud-workflow-engine format: tag: v0.0.179
            sed -i '' "s/tag: v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/tag: $NEW_VERSION/" "$file"
        else
            # site-workflow-engine format: app.image: registry/name:v0.0.210
            sed -i '' "s/:v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/:$NEW_VERSION/" "$file"
        fi
        echo "Updated $file"
    fi
}

# Update template
template_file="environment-templates/nke-site-forge/values-${APP_NAME}.yaml"
update_version_in_file "$template_file"

# Update environments for specified type
for values_file in environments/${ENV_TYPE}/forge/*/values-${APP_NAME}.yaml; do
    [[ -f "$values_file" ]] && update_version_in_file "$values_file"
done