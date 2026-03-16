# Resource Deep Dive

## Elastic Beanstalk

- `aws_elastic_beanstalk_application`: logical app container in AWS.
- `aws_elastic_beanstalk_environment`: running environment (single instance, Docker platform).
- Important settings include instance type, instance profile, service role, and environment properties.

Why it matters: this maps to the `application_name` and `environment_name` used in GitHub Actions deploy.

## IAM for Beanstalk

- EC2 role + instance profile: what app instances can do.
- Service role: what Elastic Beanstalk service can do on your behalf.
- Managed policy attachments are required for web tier, worker tier, multicontainer, health, and updates.

Why it matters: missing IAM policies often causes environment creation failures.

## S3 Deployment Bucket

- Stores deployment artifacts used by Elastic Beanstalk.
- `force_destroy = true` is set so learning stacks are easy to clean up.

Why it matters: GitHub Actions deploy step points to this bucket (`existing_bucket_name`).

## RDS PostgreSQL

- Free-tier-friendly class/size defaults.
- `skip_final_snapshot = true` and `deletion_protection = false` for lab teardown speed.
- Endpoint is injected into EB env vars as `PGHOST`.

Why it matters: this backs the server API persistence layer in your monorepo app.

## ElastiCache Redis

- Single-node replication group (`num_cache_clusters = 1`) for simple labs.
- `transit_encryption_mode = "preferred"` to match course guidance around compatibility.
- Endpoint is injected as `REDIS_HOST`.

Why it matters: worker/server coordination and cache usage depend on Redis availability.

## Shared Security Group

- Self-referencing ingress on `5432-6379`.
- Attached to EB instances, RDS, and Redis.

Why it matters: allows app containers and data services to communicate inside the same group.
