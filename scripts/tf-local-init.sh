#!/usr/bin/env bash

# when a command fails, bash exits instead of continuing with the rest of the script
set -o errexit
# make the script fail, when accessing an unset variable
set -o nounset
# pipeline command is treated as failed, even if one command in the pipeline fails
set -o pipefail
# enable debug mode, by running your script as TRACE=1
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

# we assume gcloud to be downloaded and initialized
# gcloud init
# gcloud auth application-default login

# we assume aws cli to be setup
# aws login

source "$(dirname "$0")/common.sh"

function bucket_exists() {
    local bucket_name="$1"
    local project="$2"
    local existing_bucket
    existing_bucket=$(gcloud storage buckets list --filter=name="$bucket_name" --format="value(name)" --project="$project")

    if [ -z "$existing_bucket" ]; then
        return 1
    else
        return 0
    fi
}

echo "Check if $SEED_PROJECT_TF_STATE_BUCKET_NAME exists"
if bucket_exists "$SEED_PROJECT_TF_STATE_BUCKET_NAME" "$FULL_SEED_PROJECT_NAME"; then
    terraform init -backend-config="bucket=$SEED_PROJECT_TF_STATE_BUCKET_NAME" "$@"
else
    echo "Missing bucket '$SEED_PROJECT_TF_STATE_BUCKET_NAME'; cannot initialize backend"
    exit 1 
fi
