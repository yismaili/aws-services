
output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.servers[*].id
}

output "instance_names" {
  description = "List of instance names"
  value       = aws_instance.servers[*].tags.Name
}

output "instance_public_ips" {
  description = "List of instance public IP addresses"
  value       = aws_instance.servers[*].public_ip
}

output "instance_private_ips" {
  description = "List of instance private IP addresses"
  value       = aws_instance.servers[*].private_ip
}

output "instance_public_dns" {
  description = "List of instance public DNS names"
  value       = aws_instance.servers[*].public_dns
}

output "instance_info" {
  description = "Detailed information about all EC2 instances"
  value = {
    for i, instance in aws_instance.servers :
    instance.tags.Name => {
      id              = instance.id
      name            = instance.tags.Name
      public_ip       = instance.public_ip
      private_ip      = instance.private_ip
      public_dns      = instance.public_dns
      availability_zone = instance.availability_zone
      instance_type   = instance.instance_type
      ami             = instance.ami
      state           = instance.instance_state
      vpc_id          = instance.vpc_security_group_ids
      subnet_id       = instance.subnet_id
      key_name        = instance.key_name
      monitoring      = instance.monitoring
      tags            = instance.tags
    }
  }
}

output "vpc_info" {
  description = "VPC information"
  value = var.create_vpc ? {
    vpc_id     = aws_vpc.main[0].id
    vpc_cidr   = aws_vpc.main[0].cidr_block
    subnet_id  = aws_subnet.main[0].id
    igw_id     = aws_internet_gateway.main[0].id
  } : null
}

output "security_group_info" {
  description = "Security group information"
  value = {
    id   = aws_security_group.server_sg.id
    name = aws_security_group.server_sg.name
  }
}

output "ssh_connections" {
  description = "SSH connection commands for all instances"
  value = [
    for instance in aws_instance.servers :
    "ssh ubuntu@${instance.public_ip}"
  ]
}

output "key_pair_name" {
  description = "Name of the created key pair"
  value       = aws_key_pair.main.key_name
}


output "aws_region" {
  description = "AWS region where resources were created"
  value       = var.aws_region
}


output "estimated_monthly_cost" {
  description = "Estimated monthly cost in USD (approximate, based on instance type)"
  value = {
    for i, instance in aws_instance.servers :
    instance.tags.Name => {
      instance_type = instance.instance_type
      note          = "This is an estimate. Check AWS pricing for accurate costs."
    }
  }
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = var.create_load_balancer ? aws_lb.main[0].dns_name : null
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = var.create_load_balancer ? "http://${aws_lb.main[0].dns_name}" : null
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = var.create_load_balancer ? aws_lb.main[0].arn : null
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.create_load_balancer ? aws_lb_target_group.main[0].arn : null
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer (for Route53)"
  value       = var.create_load_balancer ? aws_lb.main[0].zone_id : null
}