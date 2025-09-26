# Instance Information
output "frontend_instance_info" {
  description = "Frontend instance information"
  value = {
    id            = aws_instance.frontend.id
    name          = aws_instance.frontend.tags.Name
    public_ip     = aws_instance.frontend.public_ip
    private_ip    = aws_instance.frontend.private_ip
    public_dns    = aws_instance.frontend.public_dns
    subnet_id     = aws_instance.frontend.subnet_id
    instance_type = aws_instance.frontend.instance_type
    tier          = "Frontend"
  }
}

output "backend_instance_info" {
  description = "Backend instance information"
  value = {
    id            = aws_instance.backend.id
    name          = aws_instance.backend.tags.Name
    private_ip    = aws_instance.backend.private_ip
    subnet_id     = aws_instance.backend.subnet_id
    instance_type = aws_instance.backend.instance_type
    tier          = "Backend"
  }
}

output "database_instance_info" {
  description = "Database instance information"
  value = {
    id            = aws_instance.database.id
    name          = aws_instance.database.tags.Name
    private_ip    = aws_instance.database.private_ip
    subnet_id     = aws_instance.database.subnet_id
    instance_type = aws_instance.database.instance_type
    tier          = "Database"
  }
}

# Network Information
output "vpc_info" {
  description = "VPC and subnet information"
  value = {
    vpc_id           = aws_vpc.main.id
    vpc_cidr         = aws_vpc.main.cidr_block
    public_subnet = {
      id   = aws_subnet.public.id
      cidr = aws_subnet.public.cidr_block
      az   = aws_subnet.public.availability_zone
    }
    private_backend_subnet = {
      id   = aws_subnet.private_backend.id
      cidr = aws_subnet.private_backend.cidr_block
      az   = aws_subnet.private_backend.availability_zone
    }
    private_database_subnet = {
      id   = aws_subnet.private_database.id
      cidr = aws_subnet.private_database.cidr_block
      az   = aws_subnet.private_database.availability_zone
    }
    internet_gateway_id = aws_internet_gateway.main.id
    nat_gateway_id      = aws_nat_gateway.main.id
    nat_gateway_ip      = aws_eip.nat.public_ip
  }
}

# Security Group Information
output "security_groups" {
  description = "Security group information"
  value = {
    frontend_sg = {
      id   = aws_security_group.frontend_sg.id
      name = aws_security_group.frontend_sg.name
    }
    backend_sg = {
      id   = aws_security_group.backend_sg.id
      name = aws_security_group.backend_sg.name
    }
    database_sg = {
      id   = aws_security_group.database_sg.id
      name = aws_security_group.database_sg.name
    }
  }
}

# Network ACL Information
output "network_acls" {
  description = "Network ACL information"
  value = {
    public_nacl = {
      id = aws_network_acl.public.id
    }
    private_nacl = {
      id = aws_network_acl.private.id
    }
  }
}

# Connection Information
output "ssh_connections" {
  description = "SSH connection commands"
  value = {
    frontend = "ssh ubuntu@${aws_instance.frontend.public_ip}"
    backend  = "ssh -o ProxyCommand='ssh -W %h:%p ubuntu@${aws_instance.frontend.public_ip}' ubuntu@${aws_instance.backend.private_ip}"
    database = "ssh -o ProxyCommand='ssh -W %h:%p ubuntu@${aws_instance.frontend.public_ip}' ubuntu@${aws_instance.database.private_ip}"
  }
}

# Route Table Information
output "route_tables" {
  description = "Route table information"
  value = {
    public_rt = {
      id = aws_route_table.public.id
    }
    private_rt = {
      id = aws_route_table.private.id
    }
  }
}

# Key pair information
output "key_pair_name" {
  description = "Name of the created key pair"
  value       = aws_key_pair.main.key_name
}

# Region information
output "aws_region" {
  description = "AWS region where resources were created"
  value       = var.aws_region
}

# Architecture Summary
output "architecture_summary" {
  description = "Summary of the 3-tier architecture"
  value = {
    frontend = {
      instance    = aws_instance.frontend.id
      subnet_type = "Public"
      subnet_cidr = aws_subnet.public.cidr_block
      public_ip   = aws_instance.frontend.public_ip
      access      = "Direct internet access via IGW"
    }
    backend = {
      instance    = aws_instance.backend.id
      subnet_type = "Private"
      subnet_cidr = aws_subnet.private_backend.cidr_block
      private_ip  = aws_instance.backend.private_ip
      access      = "Internet access via NAT Gateway, SSH via Frontend (bastion)"
    }
    database = {
      instance    = aws_instance.database.id
      subnet_type = "Private"
      subnet_cidr = aws_subnet.private_database.cidr_block
      private_ip  = aws_instance.database.private_ip
      access      = "Internet access via NAT Gateway, SSH via Frontend (bastion)"
    }
  }
}

# Cost estimation helper
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    instances = {
      frontend = {
        type = aws_instance.frontend.instance_type
        note = "Public instance"
      }
      backend = {
        type = aws_instance.backend.instance_type
        note = "Private instance"
      }
      database = {
        type = aws_instance.database.instance_type
        note = "Private instance"
      }
    }
    networking = {
      nat_gateway = "~$45/month"
      elastic_ip  = "~$3.6/month"
      note        = "Additional costs for NAT Gateway and Elastic IP"
    }
    total_note = "This is an estimate. Check AWS pricing for accurate costs."
  }
}

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}
output "backend_private_ip" {
  value = aws_instance.backend.private_ip
}
output "database_private_ip" {
  value = aws_instance.database.private_ip
}
