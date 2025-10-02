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

output "rds_instance_info" {
  description = "RDS database information"
  value = {
    endpoint           = aws_db_instance.postgres.endpoint
    address            = aws_db_instance.postgres.address
    port               = aws_db_instance.postgres.port
    database_name      = aws_db_instance.postgres.db_name
    engine             = aws_db_instance.postgres.engine
    engine_version     = aws_db_instance.postgres.engine_version
    instance_class     = aws_db_instance.postgres.instance_class
    allocated_storage  = aws_db_instance.postgres.allocated_storage
    multi_az           = aws_db_instance.postgres.multi_az
  }
  sensitive = true
}

output "database_connection_string" {
  description = "Database connection string (sensitive)"
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.endpoint}/${var.db_name}"
  sensitive   = true
}

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
    private_database_subnet_1 = {
      id   = aws_subnet.private_database_1.id
      cidr = aws_subnet.private_database_1.cidr_block
      az   = aws_subnet.private_database_1.availability_zone
    }
    private_database_subnet_2 = {
      id   = aws_subnet.private_database_2.id
      cidr = aws_subnet.private_database_2.cidr_block
      az   = aws_subnet.private_database_2.availability_zone
    }
    internet_gateway_id = aws_internet_gateway.main.id
    nat_gateway_id      = aws_nat_gateway.main.id
    nat_gateway_ip      = aws_eip.nat.public_ip
  }
}

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
    rds_sg = {
      id   = aws_security_group.rds_sg.id
      name = aws_security_group.rds_sg.name
    }
  }
}

output "ssh_connections" {
  description = "SSH connection commands"
  value = {
    frontend = "ssh ubuntu@${aws_instance.frontend.public_ip}"
    backend  = "ssh -o ProxyCommand='ssh -W %h:%p ubuntu@${aws_instance.frontend.public_ip}' ubuntu@${aws_instance.backend.private_ip}"
  }
}

output "application_urls" {
  description = "Application URLs"
  value = {
    frontend = "http://${aws_instance.frontend.public_ip}:3000"
    backend  = "Backend accessible from frontend at http://${aws_instance.backend.private_ip}:3001"
  }
}

output "architecture_summary" {
  description = "Summary of the 3-tier architecture"
  value = {
    frontend = {
      instance    = aws_instance.frontend.id
      subnet_type = "Public"
      subnet_cidr = aws_subnet.public.cidr_block
      public_ip   = aws_instance.frontend.public_ip
      access      = "Direct internet access via IGW"
      setup       = "Node.js 20.x, PM2, Nginx"
    }
    backend = {
      instance    = aws_instance.backend.id
      subnet_type = "Private"
      subnet_cidr = aws_subnet.private_backend.cidr_block
      private_ip  = aws_instance.backend.private_ip
      access      = "Internet access via NAT Gateway, SSH via Frontend (bastion)"
      setup       = "Node.js 20.x, PM2, PostgreSQL client"
    }
    database = {
      type        = "RDS PostgreSQL"
      endpoint    = aws_db_instance.postgres.endpoint
      subnet_type = "Private (Multi-AZ capable)"
      access      = "Accessible only from Backend via security group"
      setup       = "Managed PostgreSQL database"
    }
  }
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    instances = {
      frontend = {
        type = aws_instance.frontend.instance_type
        note = "Public instance - ~$15-30/month"
      }
      backend = {
        type = aws_instance.backend.instance_type
        note = "Private instance - ~$15-30/month"
      }
    }
    database = {
      rds_instance = "${aws_db_instance.postgres.instance_class} - ~$15-25/month"
      storage      = "${aws_db_instance.postgres.allocated_storage}GB - ~$2-5/month"
      backups      = "Backup storage - varies"
    }
    networking = {
      nat_gateway = "~$32/month"
      elastic_ip  = "~$3.6/month"
      data_transfer = "varies based on usage"
    }
    total_estimate = "~$82-125/month (excluding data transfer)"
    note = "This is an estimate. Check AWS pricing for accurate costs."
  }
}

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_private_ip" {
  value = aws_instance.backend.private_ip
}

output "database_endpoint" {
  value = aws_db_instance.postgres.endpoint
  sensitive = true
}