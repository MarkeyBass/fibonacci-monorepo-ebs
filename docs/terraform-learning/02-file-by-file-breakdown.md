# File-by-File Breakdown

## `terraform/main.tf`

Contains providers, data sources, and all AWS resources:

- Elastic Beanstalk app + environment
- IAM roles and instance profile
- S3 deployment artifact bucket
- RDS PostgreSQL
- ElastiCache Redis
- Shared security group and subnet groups

This is where dependency wiring happens.

## `terraform/variables.tf`

Defines configurable inputs such as:

- Region and naming
- DB/Redis sizing and identifiers
- Elastic Beanstalk names
- Optional explicit deployment bucket name

For learning, keep defaults first, then change one variable at a time.

## `terraform/locals.tf`

Holds computed values:

- Auto-generated bucket naming fallback
- Standardized merged tags

Use locals when the same expression appears in multiple resources.

## `terraform/outputs.tf`

Exposes key values after `apply`:

- EB app/environment names
- Bucket name
- RDS and Redis endpoints
- A grouped output for GitHub Actions deploy settings

Outputs are your bridge between infrastructure and CI/CD.

## `terraform/terraform.tfvars.example`

A safe template for local values. Copy to `terraform.tfvars` and customize.

## `terraform/README.md`

Operator guide with quick commands and lifecycle notes.
