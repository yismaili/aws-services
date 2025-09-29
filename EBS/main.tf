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
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "main" {
  name_prefix = "${var.project_name}-sg"
  description = "Security group for ${var.project_name}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.ssh_public_key_path)

  tags = {
    Name    = "${var.project_name}-key"
    Project = var.project_name
  }
}

#     EC2 Instance
resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.main.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = var.project_name
    Project = var.project_name
  }
}

# EBS
resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.main.availability_zone
  size              = var.ebs_volume_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name    = "${var.project_name}-data"
    Project = var.project_name
  }
}

# attach EBS
resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.main.id
}

resource "null_resource" "setup" {
  depends_on = [aws_instance.main, aws_volume_attachment.data]

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for system initialization...'",
      "sleep 30",

      # Update system
      "sudo apt-get update -y",

      # Install Docker
      "echo 'Installing Docker...'",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ubuntu",

      "echo 'Installing Docker Compose...'",
      "mkdir -p ~/.docker/cli-plugins/",
      "curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose",
      "chmod +x ~/.docker/cli-plugins/docker-compose",

    
      "docker --version",
      "docker compose version",

      # format and mount EBS volume
      "echo 'Setting up EBS volume...'",
      "sleep 5",
      "DEVICE=$(lsblk -o NAME,SIZE -dn | grep '50G' | awk '{print \"/dev/\"$1}' | head -n1)",
      "echo \"Found device: $DEVICE\"",
      "sudo mkfs -t ext4 $DEVICE",
      "sudo mkdir -p /data",
      "sudo mount $DEVICE /data",
      "sudo chown ubuntu:ubuntu /data",

      # add to fstab for auto-mount on reboot
      "echo \"$DEVICE /data ext4 defaults,nofail 0 2\" | sudo tee -a /etc/fstab"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.main.public_ip
      timeout     = "10m"
    }
  }

  triggers = {
    instance_id = aws_instance.main.id
  }
}
