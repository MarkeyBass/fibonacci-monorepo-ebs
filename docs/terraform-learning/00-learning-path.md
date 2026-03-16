# Terraform Learning Path (This Monorepo)

This path is designed for the Stephen Grider multi-container app flow:

1. Read `01-architecture-map.md` for the big picture.
2. Read `02-file-by-file-breakdown.md` to understand file roles.
3. Read `03-terraform-syntax-in-this-project.md` to learn HCL syntax in context (`data`, `resource`, `var`, `local`, nested blocks, and outputs).
4. Read `04-main-tf-annotated-walkthrough.md` to parse `main.tf` one resource at a time.
5. Read `05-resource-deep-dive.md` to learn each AWS resource.
6. Read `06-networking-concepts-for-aws-and-terraform.md` for networking mental models and AWS/Terraform patterns.
7. Run the hands-on lab in `07-apply-destroy-lab.md`.
8. Finish with `08-ci-cd-alignment.md` to connect Terraform outputs to GitHub Actions deploy settings.
9. Read `09-custom-vpc-and-vpc-networking-deep-dive.md` for the custom VPC migration and VPC-focused networking concepts.
10. Continue with `10-phase-2-private-subnets-and-nat-next-steps.md` to plan the private-subnet + NAT migration path.

## What you will learn

- How Terraform composes AWS services into one dependency graph.
- Why Elastic Beanstalk needs IAM roles and a deployment bucket.
- How RDS and Redis are wired into app environment variables.
- Which settings make lab infrastructure easy to destroy safely.

## Suggested pace

- Session 1 (30-45 min): architecture + file walkthrough.
- Session 2 (45-60 min): apply + verify + inspect outputs.
- Session 3 (30-45 min): destroy + rerun with custom variables.
