terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_ip_range
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_ip_range, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Public"
  }
}

resource "aws_subnet" "private_backend" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_ip_range, 8, 2)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${var.project_name}-private-backend-subnet"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private"
    Tier        = "Backend"
  }
}

# Additional subnet for RDS (required for DB subnet group)
resource "aws_subnet" "private_database_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_ip_range, 8, 3)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${var.project_name}-private-database-subnet-1"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private"
    Tier        = "Database"
  }
}

# Second subnet in different AZ for RDS requirement
resource "aws_subnet" "private_database_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_ip_range, 8, 4)
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "${var.project_name}-private-database-subnet-2"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private"
    Tier        = "Database"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.project_name}-nat-gateway"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_backend" {
  subnet_id      = aws_subnet.private_backend.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_database_1" {
  subnet_id      = aws_subnet.private_database_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_database_2" {
  subnet_id      = aws_subnet.private_database_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public.id]

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "${var.project_name}-public-nacl"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.private_backend.id, aws_subnet.private_database_1.id, aws_subnet.private_database_2.id]

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.vpc_ip_range
    from_port  = 0
    to_port    = 0
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "${var.project_name}-private-nacl"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "frontend_sg" {
  name_prefix = "${var.project_name}-frontend-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for frontend instances"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Frontend App"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-frontend-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "backend_sg" {
  name_prefix = "${var.project_name}-backend-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for backend instances"

  ingress {
    description     = "SSH from Frontend"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  ingress {
    description     = "Backend API"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-backend-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.project_name}-rds-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for RDS PostgreSQL database"

  ingress {
    description     = "PostgreSQL from Backend Security Group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  # Add this new ingress rule
  ingress {
    description = "PostgreSQL from Backend Subnet"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_backend.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_database_1.id, aws_subnet.private_database_2.id]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.project_name}-postgres"
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  publicly_accessible    = false
  skip_final_snapshot    = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment == "dev" ? null : "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  backup_retention_period = var.db_backup_retention_days
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  multi_az               = var.db_multi_az
  deletion_protection    = var.environment == "prod" ? true : false

  tags = {
    Name        = "${var.project_name}-postgres"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.ssh_public_key_path)

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_instance" "frontend" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.main.key_name
  vpc_security_group_ids  = [aws_security_group.frontend_sg.id]
  subnet_id               = aws_subnet.public.id
  disable_api_termination = var.enable_termination_protection
  monitoring              = var.enable_detailed_monitoring

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "${var.project_name}-frontend"
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Frontend"
  }
}

resource "aws_instance" "backend" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.main.key_name
  vpc_security_group_ids  = [aws_security_group.backend_sg.id]
  subnet_id               = aws_subnet.private_backend.id
  disable_api_termination = var.enable_termination_protection
  monitoring              = var.enable_detailed_monitoring

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "${var.project_name}-backend"
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Backend"
  }
}

resource "null_resource" "setup_frontend" {
  depends_on = [aws_instance.frontend]

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system initialization...'",
      "sleep 30",
      "sudo apt-get update -y",
      "sudo pkill -f 'apt|dpkg|unattended-upgrade' 2>/dev/null || true",
      "sleep 10",
      "sudo rm -f /var/lib/dpkg/lock* /var/cache/apt/archives/lock /var/lib/apt/lists/lock 2>/dev/null || true",
      "sudo dpkg --configure -a || true",
      
      "echo 'Installing Node.js...'",
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "node --version",
      "npm --version",
      
      "echo 'Installing PM2...'",
      "sudo npm install -g pm2",
      "pm2 --version",
      
      "echo 'Installing Nginx...'",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      
      var.install_additional_tools ? "sudo apt-get install -y git curl wget unzip htop tree vim" : "echo 'Skipping additional tools'",
      
      "mkdir -p ~/app",
      "echo 'Frontend setup completed!'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.frontend.public_ip
      timeout     = "10m"
    }
  }

  triggers = {
    instance_id = aws_instance.frontend.id
  }
}

resource "null_resource" "setup_backend" {
  depends_on = [aws_instance.backend, null_resource.setup_frontend, aws_db_instance.postgres]

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system initialization...'",
      "sleep 30",
      "sudo apt-get update -y",
      "sudo pkill -f 'apt|dpkg|unattended-upgrade' 2>/dev/null || true",
      "sleep 10",
      "sudo rm -f /var/lib/dpkg/lock* /var/cache/apt/archives/lock /var/lib/apt/lists/lock 2>/dev/null || true",
      "sudo dpkg --configure -a || true",
      
      "echo 'Installing Node.js...'",
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "node --version",
      "npm --version",
      
      "echo 'Installing PM2...'",
      "sudo npm install -g pm2",
      "pm2 --version",
      
      "echo 'Installing PostgreSQL client...'",
      "sudo apt-get install -y postgresql-client",
      
      var.install_additional_tools ? "sudo apt-get install -y git curl wget unzip htop tree vim" : "echo 'Skipping additional tools'",
      
      "mkdir -p ~/app",
    
      "cat > ~/app/backend/.env << EOF",
      "DATABASE_URL=postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.endpoint}/${var.db_name}",
      "DB_HOST=${aws_db_instance.postgres.address}",
      "DB_PORT=5432",
      "DB_NAME=${var.db_name}",
      "DB_USER=${var.db_username}",
      "DB_PASSWORD=${var.db_password}",
      "PORT=3001",
      "NODE_ENV=${var.environment}",
      "EOF",
      
      "echo 'Backend setup completed!'"
    ]

    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file(var.ssh_private_key_path)
      host                = aws_instance.backend.private_ip
      timeout             = "10m"
      bastion_host        = aws_instance.frontend.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file(var.ssh_private_key_path)
    }
  }

  triggers = {
    instance_id = aws_instance.backend.id
    db_endpoint = aws_db_instance.postgres.endpoint
  }
}

resource "null_resource" "copy_frontend" {
  depends_on = [null_resource.setup_frontend]

  provisioner "file" {
    source      = "${path.module}/app/frontend/"
    destination = "/home/ubuntu/app"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.frontend.public_ip
      timeout     = "10m"
    }
  }

  triggers = {
    instance_id = aws_instance.frontend.id
  }
}

resource "null_resource" "copy_backend" {
  depends_on = [null_resource.setup_backend]

  provisioner "file" {
    source      = "${path.module}/app/backend/"
    destination = "/home/ubuntu/app"

    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file(var.ssh_private_key_path)
      host                = aws_instance.backend.private_ip
      timeout             = "10m"
      bastion_host        = aws_instance.frontend.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file(var.ssh_private_key_path)
    }
  }

  triggers = {
    instance_id = aws_instance.backend.id
  }
}