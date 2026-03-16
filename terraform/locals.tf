locals {
  deployment_bucket_name = var.deployment_bucket_name != "" ? var.deployment_bucket_name : "${var.resource_name_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-eb-artifacts"

  common_tags = merge(
    {
      Project     = var.resource_name_prefix
      ManagedBy   = "terraform"
      Environment = var.elastic_beanstalk_environment_name
    },
    var.tags
  )
}
