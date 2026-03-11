#!/usr/bin/env bash

# when a command fails, bash exits instead of continuing with the rest of the script
set -o errexit
# make the script fail, when accessing an unset variable
set -o nounset
# pipeline command is treated as failed, even if one command in the pipeline fails
set -o pipefail
# enable debug mode, by running your script as TRACE=1
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

unset AWS_PROFILE
export AWS_ACCESS_KEY_ID=$(op read "op://kh-development/aws-koenighotze-terraform-credentials/AWS_ACCESS_KEY_ID")
export AWS_SECRET_ACCESS_KEY=$(op read "op://kh-development/aws-koenighotze-terraform-credentials/AWS_SECRET_ACCESS_KEY")
