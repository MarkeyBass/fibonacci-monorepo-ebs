# Terraform Syntax in This Project

This guide explains Terraform syntax using the exact files in this repo.
If `main.tf` looked confusing, this is your decoder.

---

## 1) The basic Terraform "sentence"

Most Terraform code looks like:

```hcl
block_type "type_or_provider" "local_name" {
  argument = value
  nested_block {
    argument = value
  }
}
```

In this repo:

- `resource "aws_s3_bucket" "deployment_artifacts" { ... }`
- `data "aws_vpc" "default" { ... }`
- `variable "aws_region" { ... }`
- `locals { ... }`
- `output "deployment_bucket_name" { ... }`

Think of it as:

- **what kind of thing** (`resource`, `data`, `variable`, `output`)
- **which provider/object type** (`aws_s3_bucket`, `aws_vpc`, etc.)
- **your local label** (`deployment_artifacts`, `default`) used for references.

---

## 2) `data` vs `resource` (the big one)

### `data` block = read/query something that already exists (or provider catalog info)

Example from this project:

```hcl
data "aws_elastic_beanstalk_solution_stack" "docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux (.*) running Docker$"
}
```

What it means:

- Terraform asks AWS: "give me the latest EB Docker platform matching this pattern."
- Terraform **does not create** this platform.
- Later we reference it as:
  - `data.aws_elastic_beanstalk_solution_stack.docker.name`

Another example:

- `data "aws_vpc" "default" { default = true }` reads your default VPC.

### `resource` block = create/manage real infrastructure

Example:

```hcl
resource "aws_s3_bucket" "deployment_artifacts" {
  bucket        = local.deployment_bucket_name
  force_destroy = var.deployment_bucket_force_destroy
  tags          = local.common_tags
}
```

What it means:

- Terraform creates (or updates/drifts back) an S3 bucket.
- This object is managed in Terraform state.
- Reference format:
  - `aws_s3_bucket.deployment_artifacts.bucket`
  - `aws_s3_bucket.deployment_artifacts.id`

Quick memory trick:

- `data` = **look up**
- `resource` = **build/manage**

---

## 3) `variable` vs `local`

## `variable` = input from outside the module

Defined in `terraform/variables.tf`, consumed as `var.<name>`.

```hcl
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
```

Used in `main.tf`:

```hcl
provider "aws" {
  region = var.aws_region
}
```

Where values come from (highest-level practical view):

1. CLI flags (`-var`)
2. `terraform.tfvars` / `*.auto.tfvars`
3. environment variables like `TF_VAR_aws_region`
4. default in `variable` block

For your runs, keep using:

```bash
AWS_PROFILE=terraform-2026 terraform plan
```

That sets AWS credentials/profile, not a Terraform variable.

## `locals` = computed helper values inside this module

Defined in `terraform/locals.tf`, consumed as `local.<name>`.

```hcl
locals {
  deployment_bucket_name = var.deployment_bucket_name != "" ? var.deployment_bucket_name : "${var.resource_name_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-eb-artifacts"
}
```

Use locals when:

- expression is long
- value is reused in many resources
- you want cleaner, more readable `resource` blocks

Memory trick:

- `var` = "input knob"
- `local` = "derived helper"

---

## 4) Reference syntax cheat sheet (with project examples)

- `var.aws_region` -> input variable
- `local.common_tags` -> local computed value
- `data.aws_vpc.default.id` -> attribute from a data source
- `aws_security_group.multi_docker.id` -> attribute from a resource

General forms:

- `var.<variable_name>`
- `local.<local_name>`
- `data.<data_type>.<name>.<attribute>`
- `<resource_type>.<name>.<attribute>`

---

## 5) What are those nested blocks (`ingress`, `egress`, `setting`, `filter`)?

Nested blocks are provider-defined sub-objects.
They are not separate top-level resources in your file (unless you model them that way).

Example from your `aws_security_group`:

```hcl
ingress {
  from_port = 5432
  to_port   = 6379
  protocol  = "tcp"
  self      = true
}

egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

Meaning:

- `ingress` = inbound rule
- `egress` = outbound rule
- `self = true` means "allow traffic where source is this same SG" (intra-group communication).
- `protocol = "-1"` with ports `0-0` means "all protocols/all outbound".

Other nested block examples in this repo:

- `filter { ... }` inside data sources
- many `setting { ... }` blocks inside `aws_elastic_beanstalk_environment`
- `statement { ... }` and `principals { ... }` in IAM policy document data sources

---

## 6) Expressions you already use in this project

### Ternary conditional

```hcl
condition ? value_if_true : value_if_false
```

Used for optional bucket name fallback.

### String interpolation

```hcl
"${var.resource_name_prefix}-${var.aws_region}"
```

### Functions

- `merge(map1, map2)` -> combines tag maps
- `tostring(value)` -> converts numeric ports to strings for EB env vars

---

## 7) `outputs.tf`: what it is, how to get values, and why it matters

`terraform/outputs.tf` defines values Terraform prints after apply and stores in state for easy retrieval.

In this repo, outputs include:

- EB app/env names
- S3 deployment bucket name
- RDS endpoint + port
- Redis endpoint + port
- `github_actions_deploy_values` object for CI deploy wiring

Example output block:

```hcl
output "deployment_bucket_name" {
  description = "S3 bucket used for Elastic Beanstalk deployment artifacts."
  value       = aws_s3_bucket.deployment_artifacts.bucket
}
```

### How to read outputs

Run from `terraform/` with your profile:

```bash
AWS_PROFILE=terraform-2026 terraform output
```

Single value:

```bash
AWS_PROFILE=terraform-2026 terraform output deployment_bucket_name
```

Machine-readable JSON:

```bash
AWS_PROFILE=terraform-2026 terraform output -json
```

Raw string only (great for scripts):

```bash
AWS_PROFILE=terraform-2026 terraform output -raw deployment_bucket_name
```

For your workflow mapping:

```bash
AWS_PROFILE=terraform-2026 terraform output github_actions_deploy_values
```

---

## 8) In which order does Terraform execute files?

Short answer: **not by filename order**.

Terraform loads all `.tf` files in the folder as one merged configuration, then builds a dependency graph.

Execution order is based on references and dependencies:

- If `A` references `B`, Terraform creates/reads `B` first.
- Explicit `depends_on` adds manual edges when needed.

In this project:

- EB environment depends on IAM attachments and S3 public access block via `depends_on`.
- Many other dependencies are implicit through references like:
  - `vpc_id = data.aws_vpc.default.id`
  - `security_group_ids = [aws_security_group.multi_docker.id]`
  - `value = aws_db_instance.postgres.address`

So think in graph order, not file order.

---

## 9) How to read this repo's Terraform without getting lost

Use this sequence:

1. `variables.tf` - know your knobs (`var.*`)
2. `locals.tf` - know computed helpers (`local.*`)
3. `main.tf` - read data sources first, then resources
4. `outputs.tf` - see what values are exposed for humans/CI

---

## 10) Hands-on mini lab (20 minutes)

From `terraform/`:

1. `AWS_PROFILE=terraform-2026 terraform init`
2. `AWS_PROFILE=terraform-2026 terraform plan`
3. Search plan output for:
   - `aws_elastic_beanstalk_environment.this`
   - `aws_db_instance.postgres`
   - `aws_elasticache_replication_group.redis`
4. `AWS_PROFILE=terraform-2026 terraform apply`
5. `AWS_PROFILE=terraform-2026 terraform output github_actions_deploy_values`
6. `AWS_PROFILE=terraform-2026 terraform destroy`

Goal of this lab:

- connect syntax -> resources -> outputs -> operational flow.

---

## 11) Common beginner mistakes in this project

- Mixing up `data` and `resource`.
- Assuming file names control execution order.
- Forgetting `tostring(...)` where EB environment settings expect strings.
- Treating `AWS_PROFILE` as a Terraform variable (it is an AWS credential selector).
- Editing many variables at once and losing track of what changed behavior.

If you want, the next learning file can be a "read one resource at a time" annotated walkthrough of `main.tf` with line-by-line commentary.
