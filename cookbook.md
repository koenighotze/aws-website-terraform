# Cookbook: Import Existing Route 53 DNS into Terraform

A step-by-step guide to importing your blog's existing Route 53 hosted zones and ~8 DNS records into Terraform using **TF 1.5+ import blocks**, organized as **separate files per zone/record type**.

---

## Prerequisites

- Terraform ≥ 1.5 installed
- AWS CLI configured with credentials that have Route 53 read access
- Your hosted zone ID (you'll retrieve this in Step 1)

---

## Step 0a: Project Structure

Create this folder layout:

```
route53-blog/
├── providers.tf          # AWS provider config
├── variables.tf          # Shared variables (domain name)
├── outputs.tf            # Useful outputs
├── hosted-zone.tf        # The hosted zone resource + import block
├── records-a.tf          # A records + import blocks
├── records-cname.tf      # CNAME records + import blocks
├── records-mx.tf         # MX records (if any) + import blocks
├── records-txt.tf        # TXT records (if any) + import blocks
├── records-ns-soa.tf     # NS & SOA records + import blocks
└── imports.tf            # (alternative) all import blocks in one file
```

> You can keep import blocks alongside each resource or group them in `imports.tf` — both work. This guide puts them next to the resource for clarity.

**Alternative: centralized `imports.tf`**

If you prefer to keep all import blocks in one place, omit the `import { }` blocks from the individual record files and instead create `imports.tf`:

```hcl
# imports.tf — all import blocks in one place

import {
  to = aws_route53_zone.blog
  id = "Z1234567890ABC"
}

import {
  to = aws_route53_record.root_a
  id = "Z1234567890ABC_example.com_A"
}

import {
  to = aws_route53_record.www_cname
  id = "Z1234567890ABC_www.example.com_CNAME"
}

# ... add one block per resource
```

This makes it easy to see at a glance what was imported and to remove all import blocks in one edit after a successful apply.

---

## Step 0: Define Outputs

### `outputs.tf`

```hcl
output "zone_id" {
  description = "The Route 53 hosted zone ID"
  value       = aws_route53_zone.blog.zone_id
}

output "zone_arn" {
  description = "The Route 53 hosted zone ARN"
  value       = aws_route53_zone.blog.arn
}

output "name_servers" {
  description = "The authoritative name servers for the hosted zone"
  value       = aws_route53_zone.blog.name_servers
}
```

> After `terraform apply`, run `terraform output` to see these values. The `name_servers` output is especially useful to verify your domain registrar is pointing at the correct NS records.

---

## Step 1: Inventory Your Existing Resources

Run these AWS CLI commands to discover what you have.

### 1a. Find your hosted zone ID

```bash
aws route53 list-hosted-zones --output table
```

Note the zone ID (e.g., `Z1234567890ABC`). Strip the `/hostedzone/` prefix if present.

### 1b. List all records in that zone

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --output table
```

This gives you the full picture. Write down each record's:
- **Name** (e.g., `blog.example.com.`)
- **Type** (A, CNAME, MX, TXT, NS, SOA)
- **Value(s)**
- **TTL**
- Whether it's an **alias** (no TTL, has `AliasTarget` instead)

> **Tip:** Pipe to JSON for easier reference:
> ```bash
> aws route53 list-resource-record-sets \
>   --hosted-zone-id Z1234567890ABC \
>   --output json > existing-records.json
> ```

---

## Step 2: Write the Provider Config

### `providers.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Route 53 is a global service — no region needed
}
```

### `variables.tf`

```hcl
variable "domain_name" {
  description = "Your blog domain"
  type        = string
  default     = "example.com"
}
```

Override the default without editing `.tf` files by creating a `terraform.tfvars`:

```hcl
domain_name = "myblog.com"
```

Add `terraform.tfvars` to `.gitignore` — it's not sensitive here, but it's good practice since people often put secrets in this file:

```
# .gitignore
terraform.tfvars
*.tfvars
.terraform/
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.backup
```

---

## Step 3: Import the Hosted Zone

### `hosted-zone.tf`

```hcl
# ──────────────────────────────────────────────
# Import block — TF 1.5+ will import on next plan/apply
# ──────────────────────────────────────────────
import {
  to = aws_route53_zone.blog
  id = "Z1234567890ABC"  # your actual zone ID
}

# ──────────────────────────────────────────────
# Resource definition
# ──────────────────────────────────────────────
resource "aws_route53_zone" "blog" {
  name = var.domain_name

  # If this is a private zone, uncomment:
  # vpc {
  #   vpc_id = "vpc-xxxxxxxx"
  # }
}
```

### Recipe: How to find the correct `id` value

| Resource Type | Import ID Format |
|---|---|
| `aws_route53_zone` | `Z1234567890ABC` (the zone ID) |
| `aws_route53_record` | `{zone_id}_{record_name}_{record_type}` |
| `aws_route53_record` (set) | `{zone_id}_{record_name}_{record_type}_{set_identifier}` |

---

## Step 4: Import DNS Records

For each record type, create a file. Below are templates for the most common types.

### `records-a.tf` — A Records

```hcl
# ── Import: root A record ────────────────────
import {
  to = aws_route53_record.root_a
  id = "Z1234567890ABC_example.com_A"
}

resource "aws_route53_record" "root_a" {
  zone_id = aws_route53_zone.blog.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300

  records = [
    "93.184.216.34",  # replace with your actual IP
  ]
}

# ── Import: root A record (alias variant) ────
# If your A record is an ALIAS (e.g., pointing to CloudFront/ALB),
# use this pattern instead:
#
# import {
#   to = aws_route53_record.root_a_alias
#   id = "Z1234567890ABC_example.com_A"
# }
#
# resource "aws_route53_record" "root_a_alias" {
#   zone_id = aws_route53_zone.blog.zone_id
#   name    = var.domain_name
#   type    = "A"
#
#   alias {
#     name                   = "d123456.cloudfront.net"
#     zone_id                = "Z2FDTNDATAQYW2"  # CloudFront's fixed zone ID
#     evaluate_target_health = false
#   }
# }
```

### `records-cname.tf` — CNAME Records

```hcl
# ── Import: www CNAME ────────────────────────
import {
  to = aws_route53_record.www_cname
  id = "Z1234567890ABC_www.example.com_CNAME"
}

resource "aws_route53_record" "www_cname" {
  zone_id = aws_route53_zone.blog.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300

  records = ["example.com"]  # replace with actual target
}

# ── Import: another CNAME (e.g., ACM validation) ─
import {
  to = aws_route53_record.acm_validation
  id = "Z1234567890ABC__abcdef1234.example.com_CNAME"
}

resource "aws_route53_record" "acm_validation" {
  zone_id = aws_route53_zone.blog.zone_id
  name    = "_abcdef1234.${var.domain_name}"  # ACM validation record
  type    = "CNAME"
  ttl     = 300

  records = ["_xyz789.acm-validations.aws."]  # replace
}
```

### `records-txt.tf` — TXT Records

```hcl
# ── Import: SPF / verification TXT ───────────
import {
  to = aws_route53_record.root_txt
  id = "Z1234567890ABC_example.com_TXT"
}

resource "aws_route53_record" "root_txt" {
  zone_id = aws_route53_zone.blog.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 300

  # TXT values: do NOT add inner quotes — Route 53 stores them without quotes.
  # Terraform handles quoting internally. Adding escaped quotes will cause drift.
  records = [
    "v=spf1 include:_spf.google.com ~all",
  ]
}
```

### `records-mx.tf` — MX Records (if applicable)

```hcl
import {
  to = aws_route53_record.root_mx
  id = "Z1234567890ABC_example.com_MX"
}

resource "aws_route53_record" "root_mx" {
  zone_id = aws_route53_zone.blog.zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 300

  records = [
    "10 mail.example.com",
  ]
}
```

### `records-ns-soa.tf` — NS & SOA Records

> **Important:** NS and SOA records are auto-created with the zone. You usually want to import them so Terraform doesn't try to recreate them, but **be careful editing these**.

```hcl
# ── Import: NS record (delegated nameservers) ─
import {
  to = aws_route53_record.ns
  id = "Z1234567890ABC_example.com_NS"
}

resource "aws_route53_record" "ns" {
  zone_id         = aws_route53_zone.blog.zone_id
  name            = var.domain_name
  type            = "NS"
  ttl             = 172800
  allow_overwrite = true  # required for zone-apex NS

  records = [
    "ns-111.awsdns-11.com.",
    "ns-222.awsdns-22.net.",
    "ns-333.awsdns-33.org.",
    "ns-444.awsdns-44.co.uk.",
  ]
}

# ── Import: SOA record ────────────────────────
import {
  to = aws_route53_record.soa
  id = "Z1234567890ABC_example.com_SOA"
}

resource "aws_route53_record" "soa" {
  zone_id         = aws_route53_zone.blog.zone_id
  name            = var.domain_name
  type            = "SOA"
  ttl             = 900
  allow_overwrite = true

  records = [
    "ns-111.awsdns-11.com. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400",
  ]
}
```

---

## Step 5: Run the Import

```bash
# 1. Initialize
terraform init

# 2. Plan — this will import AND show you the diff
terraform plan

# 3. Review the output carefully
#    - "import" actions should appear for each resource
#    - Look for any unexpected changes (drift)
#    - If you see "destroy" or "replace" — STOP and fix your config

# 4. Apply when satisfied
terraform apply
```

### What to expect in the plan output

```
aws_route53_zone.blog: Preparing import... [id=Z1234567890ABC]
aws_route53_zone.blog: Refreshing state...
aws_route53_record.www_cname: Preparing import...
...

Plan: 9 to import, 0 to add, 0 to change, 0 to destroy.
```

If you see **changes** alongside the imports, it means your `.tf` config doesn't exactly match what's in AWS. Common culprits:

| Symptom | Fix |
|---|---|
| TTL mismatch | Update your `.tf` TTL to match the AWS value |
| Trailing dot on names | Route 53 normalizes FQDNs — Terraform handles this, but check `records` values |
| TXT quoting | Do NOT add inner quotes — Route 53 stores values without them. Use `"value"`, not `"\"value\""` |
| Alias vs non-alias | Can't mix — use the correct block |

---

## Step 6: Clean Up Import Blocks

After a successful `terraform apply`, the resources are in state. The `import` blocks are now **no-ops** — they won't re-import. You have two options:

1. **Leave them** — safe, acts as documentation of origin
2. **Remove them** — cleaner files, no functional difference

---

## Step 7: Verify and Lock Down

```bash
# Confirm state matches reality — should show no changes
terraform plan
# Expected: "No changes. Your infrastructure matches the configuration."
```

### Optional: Remote Backend (GCS)

State is stored in a GCS bucket that lives outside this project and is created elsewhere. GCS provides native state locking — no separate lock table needed.

Add an empty backend block to `providers.tf` so the bucket is never hardcoded in source control:

```hcl
terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Pass the bucket at init time using `-backend-config`:

```bash
terraform init \
  -backend-config="bucket=my-tf-state-bucket" \
  -backend-config="prefix=route53"
```

To migrate existing local state to the remote backend:

```bash
terraform init -migrate-state \
  -backend-config="bucket=my-tf-state-bucket" \
  -backend-config="prefix=route53"
```

> Authentication uses [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials). Run `gcloud auth application-default login` if you haven't already.

---

## Troubleshooting Recipes

### Recipe: "Error: Cannot import — resource already in state"

You already ran import once. Remove the import block or remove from state first:
```bash
terraform state rm aws_route53_record.www_cname
```

### Recipe: "Error: import ID invalid"

Double-check the format: `{zone_id}_{name}_{type}`. The **name** must include the trailing dot that Route 53 uses, but Terraform usually normalizes this. Try both with and without the dot:
```
Z1234567890ABC_www.example.com_CNAME
Z1234567890ABC_www.example.com._CNAME
```

### Recipe: Record has a Set Identifier (weighted/latency routing)

Append the set identifier:
```
Z1234567890ABC_www.example.com_A_my-set-id
```

### Recipe: Generating config from state (if you're lazy)

After importing, you can extract the full resource config from state:
```bash
terraform state show aws_route53_record.www_cname
```
This prints valid-ish HCL you can paste back into your `.tf` file and clean up.

### Recipe: Bulk-generate import blocks from AWS CLI

```bash
# Generate import blocks for ALL records in a zone
ZONE_ID="Z1234567890ABC"

aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID \
  --query 'ResourceRecordSets[].{Name:Name,Type:Type}' \
  --output text | while IFS=$'\t' read NAME TYPE; do
    # Create a safe resource name from the record
    SAFE_NAME=$(echo "${NAME%.}" | tr '.' '_' | tr '-' '_')
    echo "import {"
    echo "  to = aws_route53_record.${SAFE_NAME}_${TYPE,,}"
    echo "  id = \"${ZONE_ID}_${NAME}_${TYPE}\""
    echo "}"
    echo ""
done
```

> Requires bash 4+ (`${TYPE,,}` lowercase syntax). macOS ships with bash 3.2 — install a modern version via Homebrew: `brew install bash`.

> Review and fix the output — resource names may need manual cleanup.

---

## Quick Reference Card

| Action | Command |
|---|---|
| List zones | `aws route53 list-hosted-zones` |
| List records | `aws route53 list-resource-record-sets --hosted-zone-id ZONE_ID` |
| Import ID (zone) | `ZONE_ID` |
| Import ID (record) | `ZONE_ID_NAME_TYPE` |
| Check state | `terraform state list` |
| Show one resource | `terraform state show RESOURCE_ADDRESS` |
| Remove from state | `terraform state rm RESOURCE_ADDRESS` |
| Drift check | `terraform plan` (should show no changes) |