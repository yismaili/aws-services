variable "aws_access_key" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1",
      "ap-southeast-1", "ap-southeast-2", "ap-northeast-1",
      "ca-central-1", "sa-east-1"
    ], var.aws_region)
    error_message = "Region must be a valid AWS region."
  }
}

variable "project_name" {
  description = "Name of the project (used for naming resources)"
  type        = string
  default     = "vps-3tier"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key file"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "instance_type" {
  description = "EC2 instance type for all instances"
  type        = string
  default     = "t3.small"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge",
      "t3a.micro", "t3a.small", "t3a.medium", "t3a.large", "t3a.xlarge", "t3a.2xlarge",
      "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
      "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge"
    ], var.instance_type)
    error_message = "Instance type must be a supported EC2 instance type."
  }
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 25
  
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 8 and 100 GB."
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for instances"
  type        = bool
  default     = false
}

variable "enable_termination_protection" {
  description = "Enable termination protection for instances"
  type        = bool
  default     = false
}

variable "install_additional_tools" {
  description = "Install additional development tools (git, curl, unzip, etc.)"
  type        = bool
  default     = true
}

variable "vpc_ip_range" {
  description = "IP range for the VPC (CIDR notation)"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_ip_range, 0))
    error_message = "VPC IP range must be a valid CIDR block."
  }
}

# RDS Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
  
  validation {
    condition = contains([
      "db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large",
      "db.t4g.micro", "db.t4g.small", "db.t4g.medium",
      "db.m5.large", "db.m5.xlarge", "db.m5.2xlarge",
      "db.r5.large", "db.r5.xlarge", "db.r5.2xlarge"
    ], var.db_instance_class)
    error_message = "Must be a valid RDS instance class."
  }
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "Allocated storage must be between 20 and 1000 GB."
  }
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "pingpong"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
  sensitive   = true
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "Username must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

variable "db_backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
  
  validation {
    condition     = var.db_backup_retention_days >= 0 && var.db_backup_retention_days <= 35
    error_message = "Backup retention must be between 0 and 35 days."
  }
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}