#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2034
# when a command fails, bash exits instead of continuing with the rest of the script
set -o errexit
# make the script fail, when accessing an unset variable
set -o nounset
# pipeline command is treated as failed, even if one command in the pipeline fails
set -o pipefail
# enable debug mode, by running your script as TRACE=1
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

FULL_SEED_PROJECT_NAME="$(op read "op://kh-development/kh-gcp-bootstrap/seed_project_name")"
SEED_PROJECT_TF_STATE_BUCKET_NAME="kh-gcp-seed-13bf3f03-tf-state"