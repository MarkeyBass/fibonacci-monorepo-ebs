variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the custom VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_azs" {
  description = "Availability zones used for public subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for public subnets (must match public_subnet_azs length)."
  type        = list(string)
  default     = ["10.42.1.0/24", "10.42.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidr_blocks) >= 2
    error_message = "Define at least two public subnets for multi-AZ resilience."
  }
}

variable "resource_name_prefix" {
  description = "Prefix used for naming Terraform-managed resources."
  type        = string
  default     = "multi-docker-tf"
}

variable "elastic_beanstalk_application_name" {
  description = "Elastic Beanstalk application name."
  type        = string
  default     = "multi-docker-tf"
}

variable "elastic_beanstalk_environment_name" {
  description = "Elastic Beanstalk environment name."
  type        = string
  default     = "multi-docker-tf-env"
}

variable "eb_instance_type" {
  description = "EC2 instance type for Elastic Beanstalk."
  type        = string
  default     = "t3.micro"
}

variable "deployment_bucket_name" {
  description = "Optional explicit deployment bucket name. Leave empty for auto-generated name."
  type        = string
  default     = ""
}

variable "deployment_bucket_force_destroy" {
  description = "Allow Terraform to delete the deployment bucket even when non-empty."
  type        = bool
  default     = true
}

variable "db_instance_identifier" {
  description = "RDS DB instance identifier."
  type        = string
  default     = "multi-docker-tf-postgres"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "fibvalues"
}

variable "db_username" {
  description = "Database username."
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database password."
  type        = string
  default     = "postgrespassword"
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Allocated storage for PostgreSQL in GiB."
  type        = number
  default     = 20
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "redis_replication_group_id" {
  description = "ElastiCache replication group ID."
  type        = string
  default     = "multi-docker-tf-redis"
}

variable "redis_node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t3.micro"
}

variable "tags" {
  description = "Extra tags applied to resources."
  type        = map(string)
  default = {
    Purpose = "terraform-learning"
  }
}
