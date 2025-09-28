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

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create Public Subnet for Frontend
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_ip_range, 8, 1) # 10.0.1.0/24
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Public"
  }
}

# Create Private Subnet 
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

# Create Private Subnet for Database (SAME AZ as others)
resource "aws_subnet" "private_database" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_ip_range, 8, 3) # 10.0.3.0/24
  availability_zone = data.aws_availability_zones.available.names[0]  # Same AZ as others

  tags = {
    Name        = "${var.project_name}-private-database-subnet"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private"
    Tier        = "Database"
  }
}

# create NAT Gateway in Public Subnet
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

# create Route Table for Public Subnet
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

# Create Route Table for Private Subnets
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

# aaassociate Public Route Table with Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#               associate Private Route Table with Backend Subnet
resource "aws_route_table_association" "private_backend" {
  subnet_id      = aws_subnet.private_backend.id
  route_table_id = aws_route_table.private.id
}


resource "aws_route_table_association" "private_database" {
  subnet_id      = aws_subnet.private_database.id
  route_table_id = aws_route_table.private.id
}

# Network ACL for Public Subnet
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public.id]

  # Allow http .... inbound
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

  #         allow all outbound traffic
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

# network ACL for Private Subnets
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.private_backend.id, aws_subnet.private_database.id]

  # Allow traffic from VPC
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

# security Group 
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

# security Group 
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

  #                   all outbound traffic
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


resource "aws_security_group" "database_sg" {
  name_prefix = "${var.project_name}-database-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for database instances"


  ingress {
    description     = "SSH from Frontend"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-database-sg"
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
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  subnet_id              = aws_subnet.public.id
  disable_api_termination = var.enable_termination_protection
  monitoring             = var.enable_detailed_monitoring

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge({
    Name        = "${var.project_name}-frontend"
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Frontend"
    Docker      = "true"
  }, {
    for tag in var.additional_tags :
    tag => "true"
  })
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  subnet_id              = aws_subnet.private_backend.id
  disable_api_termination = var.enable_termination_protection
  monitoring             = var.enable_detailed_monitoring

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge({
    Name        = "${var.project_name}-backend"
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Backend"
    Docker      = "true"
  }, {
    for tag in var.additional_tags :
    tag => "true"
  })
}

resource "aws_instance" "database" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  subnet_id              = aws_subnet.private_database.id
  disable_api_termination = var.enable_termination_protection
  monitoring             = var.enable_detailed_monitoring

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge({
    Name        = "${var.project_name}-database"
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Database"
    Docker      = "true"
  }, {
    for tag in var.additional_tags :
    tag => "true"
  })
}

# setup env
resource "null_resource" "setup_frontend" {
  depends_on = [aws_instance.frontend]

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system initialization...'",
      "sleep 60",
      "sudo apt-get update -y",
      "sudo pkill -f 'apt|dpkg|unattended-upgrade' 2>/dev/null || true",
      "sleep 10",
      "sudo rm -f /var/lib/dpkg/lock* /var/cache/apt/archives/lock /var/lib/apt/lists/lock 2>/dev/null || true",
      "sudo dpkg --configure -a || true",
      "echo 'Installing Docker...'",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ubuntu",
      "docker --version",
      "echo 'Installing Docker Compose...'",
      "mkdir -p ~/.docker/cli-plugins/",
      var.docker_compose_version != "" ? 
        "curl -SL https://github.com/docker/compose/releases/download/${var.docker_compose_version}/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose" :
        "curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose",
      "chmod +x ~/.docker/cli-plugins/docker-compose",
      "docker compose version",
      var.install_additional_tools ? "sudo apt-get install -y git curl wget unzip htop tree vim" : "echo 'Skipping additional tools installation'"
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
  depends_on = [aws_instance.backend, null_resource.setup_frontend]

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system initialization...'",
      "sleep 60",
      "sudo apt-get update -y",
      "sudo pkill -f 'apt|dpkg|unattended-upgrade' 2>/dev/null || true",
      "sleep 10",
      "sudo rm -f /var/lib/dpkg/lock* /var/cache/apt/archives/lock /var/lib/apt/lists/lock 2>/dev/null || true",
      "sudo dpkg --configure -a || true",
      "echo 'Installing Docker...'",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ubuntu",
      "docker --version",
      "echo 'Installing Docker Compose...'",
      "mkdir -p ~/.docker/cli-plugins/",
      var.docker_compose_version != "" ? 
        "curl -SL https://github.com/docker/compose/releases/download/${var.docker_compose_version}/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose" :
        "curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose",
      "chmod +x ~/.docker/cli-plugins/docker-compose",
      "docker compose version",
      var.install_additional_tools ? "sudo apt-get install -y git curl wget unzip htop tree vim" : "echo 'Skipping additional tools installation'"
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
  }
}

resource "null_resource" "setup_database" {
  depends_on = [aws_instance.database, null_resource.setup_frontend]

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system initialization...'",
      "sleep 60",
      "sudo apt-get update -y",
      "sudo pkill -f 'apt|dpkg|unattended-upgrade' 2>/dev/null || true",
      "sleep 10",
      "sudo rm -f /var/lib/dpkg/lock* /var/cache/apt/archives/lock /var/lib/apt/lists/lock 2>/dev/null || true",
      "sudo dpkg --configure -a || true",
      "echo 'Installing Docker...'",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ubuntu",
      "docker --version",
      "echo 'Installing Docker Compose...'",
      "mkdir -p ~/.docker/cli-plugins/",
      var.docker_compose_version != "" ? 
        "curl -SL https://github.com/docker/compose/releases/download/${var.docker_compose_version}/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose" :
        "curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose",
      "chmod +x ~/.docker/cli-plugins/docker-compose",
      "docker compose version",
      var.install_additional_tools ? "sudo apt-get install -y git curl wget unzip htop tree vim" : "echo 'Skipping additional tools installation'"
    ]

    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file(var.ssh_private_key_path)
      host                = aws_instance.database.private_ip
      timeout             = "15m"  # Increased timeout
      bastion_host        = aws_instance.frontend.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file(var.ssh_private_key_path)
    }
  }

  triggers = {
    instance_id = aws_instance.database.id
  }
}