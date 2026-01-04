terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate SSH key pair (optional)
resource "tls_private_key" "ssh" {
  count     = var.create_key_pair && var.generate_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save generated private key locally
resource "local_file" "private_key" {
  count           = var.create_key_pair && var.generate_ssh_key ? 1 : 0
  content         = tls_private_key.ssh[0].private_key_openssh
  filename        = "${var.ssh_key_output_path}/${var.project_name}-key.pem"
  file_permission = "0600"
}

# Save generated public key locally
resource "local_file" "public_key" {
  count           = var.create_key_pair && var.generate_ssh_key ? 1 : 0
  content         = tls_private_key.ssh[0].public_key_openssh
  filename        = "${var.ssh_key_output_path}/${var.project_name}-key.pub"
  file_permission = "0644"
}

# Create SSH key pair in AWS (conditional)
resource "aws_key_pair" "deployer" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.project_name}-deployer-key"
  public_key = var.generate_ssh_key ? tls_private_key.ssh[0].public_key_openssh : file(var.ssh_public_key_path)
}

# Use existing or created key pair
locals {
  key_pair_name = var.create_key_pair ? aws_key_pair.deployer[0].key_name : var.existing_key_pair_name
  private_key_path = var.generate_ssh_key ? "${var.ssh_key_output_path}/${var.project_name}-key.pem" : "~/.ssh/id_rsa"
}

# Security Group
resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web server - SSH, HTTP, HTTPS"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-web-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = local.key_pair_name
  vpc_security_group_ids = [aws_security_group.web_server.id]
  subnet_id              = var.subnet_id

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    deploy_user = var.deploy_user
  })

  tags = {
    Name        = "${var.project_name}-web-server"
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP (optional, for persistent IP)
resource "aws_eip" "web_server" {
  count    = var.use_elastic_ip ? 1 : 0
  instance = aws_instance.web_server.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-web-eip"
    Project     = var.project_name
    Environment = var.environment
  }
}
