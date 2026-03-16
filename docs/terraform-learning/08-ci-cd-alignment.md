# CI/CD Alignment with `.github/workflows/deploy.yaml`

Your deploy workflow uses `einaregilsson/beanstalk-deploy` and expects:

- `application_name`
- `environment_name`
- `existing_bucket_name`
- `region`

These correspond directly to Terraform outputs in `terraform/outputs.tf`.

## Mapping Table

- `application_name` <- `elastic_beanstalk_application_name`
- `environment_name` <- `elastic_beanstalk_environment_name`
- `existing_bucket_name` <- `deployment_bucket_name`
- `region` <- `aws_region`

## Suggested workflow update pattern

After `terraform apply`, copy output values into `.github/workflows/deploy.yaml` deploy step (or into GitHub Actions repository variables if you prefer parameterization).

## Secrets remain in GitHub

Keep the following as GitHub Secrets (not Terraform outputs):

- `AWS_ACCESS_KEY`
- `AWS_SECRET_KEY`
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

## Why this matters for learning

- You see how IaC outputs become deployment inputs.
- You avoid hardcoded stale values in workflow files.
- You can recreate/destroy environments and still keep deployment config synchronized quickly.
