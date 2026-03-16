output "aws_region" {
  description = "Region used by Terraform."
  value       = var.aws_region
}

output "elastic_beanstalk_application_name" {
  description = "Elastic Beanstalk application name."
  value       = aws_elastic_beanstalk_application.this.name
}

output "elastic_beanstalk_environment_name" {
  description = "Elastic Beanstalk environment name."
  value       = aws_elastic_beanstalk_environment.this.name
}

output "elastic_beanstalk_environment_cname" {
  description = "Elastic Beanstalk environment CNAME."
  value       = aws_elastic_beanstalk_environment.this.cname
}

output "deployment_bucket_name" {
  description = "S3 bucket used for Elastic Beanstalk deployment artifacts."
  value       = aws_s3_bucket.deployment_artifacts.bucket
}

output "security_group_id" {
  description = "Shared security group ID."
  value       = aws_security_group.multi_docker.id
}

output "postgres_endpoint" {
  description = "RDS PostgreSQL endpoint address."
  value       = aws_db_instance.postgres.address
}

output "postgres_port" {
  description = "RDS PostgreSQL port."
  value       = aws_db_instance.postgres.port
}

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint address."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "ElastiCache Redis port."
  value       = aws_elasticache_replication_group.redis.port
}

output "github_actions_deploy_values" {
  description = "Values to copy into .github/workflows/deploy.yaml deploy step."
  value = {
    application_name     = aws_elastic_beanstalk_application.this.name
    environment_name     = aws_elastic_beanstalk_environment.this.name
    existing_bucket_name = aws_s3_bucket.deployment_artifacts.bucket
    region               = var.aws_region
  }
}
