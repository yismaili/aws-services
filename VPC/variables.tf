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

variable "docker_compose_version" {
  description = "Version of Docker Compose to install (empty for latest)"
  type        = string
  default     = "v2.24.0"
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

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = list(string)
  default     = ["docker", "docker-compose", "3-tier"]
}