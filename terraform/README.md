# Monorepo Terraform (Learning Stack)

This folder creates a disposable AWS stack for the multi-container monorepo:

- Elastic Beanstalk (Docker, single instance)
- RDS PostgreSQL
- ElastiCache Redis
- Shared security group between EB/RDS/Redis
- S3 deployment bucket used by Elastic Beanstalk deploys
- IAM roles and instance profile required by Elastic Beanstalk

## Start here for syntax

If you want a project-specific Terraform language walkthrough, read:

- `../docs/terraform-learning/03-terraform-syntax-in-this-project.md`

## Why this is learning-friendly

The defaults are intentionally sandbox-oriented:

- `skip_final_snapshot = true` and `deletion_protection = false` on RDS
- one-node Redis deployment
- `force_destroy = true` on deployment bucket

This makes `terraform destroy` practical after each lab run.

## Quick start

1. Copy example vars:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Initialize and preview:

   ```bash
   terraform init
   terraform plan
   ```

3. Create infrastructure:

   ```bash
   terraform apply
   ```

4. Print CI deploy values:

   ```bash
   terraform output github_actions_deploy_values
   ```

5. Clean up:

   ```bash
   terraform destroy
   ```

## GitHub Actions alignment

Your deploy step in `.github/workflows/deploy.yaml` expects:

- `application_name`
- `environment_name`
- `existing_bucket_name`
- `region`

All four are emitted from Terraform outputs so you can keep infra and deploy config synchronized.
