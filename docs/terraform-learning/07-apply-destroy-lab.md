# Apply/Destroy Lab

This lab teaches full lifecycle control: create, inspect, deploy mapping, and destroy.

## 1) Prepare

From the repo root:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Optionally edit names to avoid collisions in your AWS account.

## 2) Initialize and validate

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Checkpoint:

- Plan should include EB, IAM, S3, RDS, Redis, SG, and subnet groups.

## 3) Apply

```bash
terraform apply
```

Expected:

- AWS begins provisioning.
- RDS/Redis can take several minutes.
- EB health may move through warning states while dependencies settle.

## 4) Inspect outputs

```bash
terraform output
terraform output github_actions_deploy_values
```

Capture:

- `application_name`
- `environment_name`
- `existing_bucket_name`
- `region`

## 5) Verify in AWS Console

- Elastic Beanstalk environment exists and moves to healthy.
- RDS endpoint is present.
- ElastiCache endpoint is present.
- Shared security group is attached where expected.

## 6) Destroy

```bash
terraform destroy
```

Expected:

- Teardown can take time, especially RDS and ElastiCache.
- S3 bucket should be removed even if it contains objects because force-destroy is enabled.

## 7) Repeatability exercise

- Change `resource_name_prefix` in `terraform.tfvars`.
- Run `apply` and `destroy` again.
- Compare output names to confirm variable-driven infrastructure behavior.
