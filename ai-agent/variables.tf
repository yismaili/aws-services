variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for naming resources)"
  type        = string
  default     = "my-project"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
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
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ebs_volume_size" {
  description = "Size of the EBS data volume in GB"
  type        = number
  default     = 50
  
  validation {
    condition     = var.ebs_volume_size >= 10 && var.ebs_volume_size <= 1000
    error_message = "EBS volume size must be between 10 and 1000 GB."
  }
}