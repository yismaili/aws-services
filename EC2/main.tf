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
}

# Get the latest Ubuntu AMI (Amazon Machine Image) we use it to automatically selects the latest Ubuntu AMI,
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"] #hardware virtual machine
  }
}

# Create VPC if specified
resource "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0

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
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create subnet
resource "aws_subnet" "main" {
  count = var.create_vpc ? 1 : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(var.vpc_ip_range, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-subnet"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create route table
resource "aws_route_table" "main" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name        = "${var.project_name}-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "main" {
  count = var.create_vpc ? 1 : 0

  subnet_id      = aws_subnet.main[0].id
  route_table_id = aws_route_table.main[0].id
}

# Create security group
resource "aws_security_group" "server_sg" {
  name_prefix = "${var.project_name}-sg"
  vpc_id      = var.create_vpc ? aws_vpc.main[0].id : null

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Docker daemon
  ingress {
    description = "Docker"
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create key pair
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.ssh_public_key_path)

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create multiple EC2 instances
resource "aws_instance" "servers" {
  # Number of instances to launch (from variable)
  count = var.instance_count

  # AMI (Ubuntu image ID fetched dynamically)
  ami           = data.aws_ami.ubuntu.id
  
  # EC2 instance type (e.g., t3.micro, t3.medium)
  instance_type = var.instance_type

  # SSH key pair to access the instance
  key_name = aws_key_pair.main.key_name

  # Security group(s) to attach
  vpc_security_group_ids = [aws_security_group.server_sg.id]

  # Subnet for the instance:
  # If creating a VPC, use the first subnet
  # Otherwise, set to null (may use default subnet if available)
  subnet_id = var.create_vpc ? aws_subnet.main[0].id : null

  # Prevent accidental termination if enabled
  disable_api_termination = var.enable_termination_protection

  # Enable detailed monitoring (CloudWatch) if requested
  monitoring = var.enable_detailed_monitoring

  # Root volume configuration
  root_block_device {
    volume_type           = "gp3"                # Fast, cost-effective storage
    volume_size           = var.root_volume_size # Disk size in GB
    delete_on_termination = true                 # Auto-delete when instance is destroyed
    encrypted             = true                 # Encrypt volume by default
  }

  # Tags for identification
  tags = merge({
    Name        = var.instance_names[count.index] # Instance name (from list)
    Environment = var.environment                 # Environment (e.g., dev, prod)
    Project     = var.project_name                # Project name
    Docker      = "true"                          # Mark that it supports Docker
  }, {
    # Add extra tags, with values set to "true"
    for tag in var.additional_tags :
    tag => "true"
  })
}

# Setup server with Docker
resource "null_resource" "setup_server" {
  count = var.instance_count

  depends_on = [aws_instance.servers]

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system initialization...'",
      "sleep 60",

      # Update system
      "sudo apt-get update -y",
      
      # Clear any package management conflicts
      "sudo pkill -f 'apt|dpkg|unattended-upgrade' 2>/dev/null || true",
      "sleep 10",
      "sudo rm -f /var/lib/dpkg/lock* /var/cache/apt/archives/lock /var/lib/apt/lists/lock 2>/dev/null || true",
      "sudo dpkg --configure -a || true",

      # Install Docker using official script
      "echo 'Installing Docker...'",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ubuntu",
      "sudo usermod -aG docker root",
      
      # Verify Docker installation
      "docker --version",
      "sudo systemctl is-active docker",

      # Install Docker Compose
      "echo 'Installing Docker Compose...'",
      "mkdir -p ~/.docker/cli-plugins/",
      var.docker_compose_version != "" ? 
        "curl -SL https://github.com/docker/compose/releases/download/${var.docker_compose_version}/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose" :
        "curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose",
      "chmod +x ~/.docker/cli-plugins/docker-compose",
      "sleep 10",
      "docker compose version",

      # Install additional tools if specified
      var.install_additional_tools ? "sudo apt-get install -y git curl wget unzip htop tree vim" : "echo 'Skipping additional tools installation'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.servers[count.index].public_ip
      timeout     = "10m"
    }
  }

  triggers = {
    instance_id = aws_instance.servers[count.index].id
  }
}

# provisioner to copy the src directory
resource "null_resource" "copy_src_directory" {
  count = var.instance_count

  depends_on = [null_resource.setup_server]

  provisioner "file" {
    source      = "./src"           
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.servers[count.index].public_ip
      timeout     = "10m"
    }
  }

  triggers = {
    src_hash = sha256(join("", [for f in fileset("./src", "**") : filesha256("./src/${f}")]))
  }
}