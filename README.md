# aws-website-terraform

Terraform configuration for the AWS Route 53 hosted zone and DNS records for `koenighotze.de`.

The Terraform state is stored in a GCS bucket. AWS credentials are managed via [1Password CLI](https://developer.1password.com/docs/cli/).

## What this manages

- Route 53 hosted zone for `koenighotze.de`
- A records, CAA records, NS/SOA records, TXT records
- All DNS resources were imported from an existing hosted zone (zone ID `Z34QRYXKXUA5NK`)

## Prerequisites

| Tool | Purpose |
| ---- | --------- |
| [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5 | Infrastructure provisioning |
| [AWS CLI](https://aws.amazon.com/cli/) | AWS authentication |
| [gcloud CLI](https://cloud.google.com/sdk/docs/install) | GCS backend authentication |
| [1Password CLI (`op`)](https://developer.1password.com/docs/cli/) | Local secrets management |
| [tflint](https://github.com/terraform-linters/tflint) | Linting (optional, for `check.sh`) |
| [Trivy](https://aquasecurity.github.io/trivy/) | Security scanning (optional, for `check.sh`) |
| [Checkov](https://www.checkov.io/) | Security scanning (optional, for `check.sh`) |

## Local usage

### 1. Authenticate

```bash
# Authenticate AWS CLI
aws login

# Authenticate gcloud for the GCS state backend
gcloud auth application-default login
```

AWS credentials (access key + secret) are read automatically from 1Password by the scripts — no manual export needed.

### 2. Initialise

```bash
./scripts/tf-local-init.sh
```

Checks that the GCS state bucket exists and runs `terraform init` with the correct backend config.

### 3. Plan

```bash
./scripts/tf-plan.sh
```

Runs `terraform plan` and writes the plan to `tf.plan`.

### 4. Apply

```bash
./scripts/tf-apply.sh
```

Applies the previously generated `tf.plan`.

### 5. Lint and security checks

```bash
./scripts/check.sh
```

Runs tflint, `terraform validate`, `terraform fmt`, Trivy, and Checkov against the local working directory.

### Debugging

Prefix any script with `TRACE=1` to enable bash `xtrace` output:

```bash
TRACE=1 ./scripts/tf-plan.sh
```

### Clean up shell scripts

```bash
./scripts/clean-sh.sh
```

Runs `shellcheck`, `shfmt`, and `beautysh` to lint and format all scripts in `scripts/`.

## CI/CD

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `lint.yml` | Push / PR to main | terraform fmt, validate, tflint, shellcheck |
| `security.yml` | Push / PR to main | Trivy and Checkov IaC scans, results uploaded to GitHub Security tab |
| `plan.yml` | Push to main / PR to main | `terraform plan` output to job log |

### Required GitHub configuration

**Variables** (Settings → Secrets and variables → Actions → Variables):

| Variable | Value |
| --------- | ----- |
| `TF_STATE_BUCKET` | GCS bucket name for Terraform state |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | WIF provider resource name |
| `GCP_SERVICE_ACCOUNT` | Service account email used by the plan workflow |

**Secrets** (Settings → Secrets and variables → Actions → Secrets):

| Secret | Value |
| ------ | ----- |
| `AWS_ACCESS_KEY_ID` | AWS access key with Route 53 permissions |
| `AWS_SECRET_ACCESS_KEY` | Corresponding secret key |

## Outputs

After apply, Terraform outputs:

| Output | Description |
| ------ | ----------- |
| `zone_id` | Route 53 hosted zone ID |
| `zone_arn` | Route 53 hosted zone ARN |
| `name_servers` | Authoritative name servers for the zone |
