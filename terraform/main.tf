terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── Provider ─────────────────────────────────────────────────────────────────
provider "aws" {
  region = var.aws_region
  # Credentials are picked up automatically from ~/.aws/credentials
  # which was configured when you ran `aws configure`
}

# ── SSH Key Pair ──────────────────────────────────────────────────────────────
resource "aws_key_pair" "project3" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# ── VPC ───────────────────────────────────────────────────────────────────────
resource "aws_vpc" "project3_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project3-vpc"
  }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────
resource "aws_internet_gateway" "project3_igw" {
  vpc_id = aws_vpc.project3_vpc.id

  tags = {
    Name = "project3-igw"
  }
}

# ── Public Subnet ─────────────────────────────────────────────────────────────
resource "aws_subnet" "project3_subnet" {
  vpc_id                  = aws_vpc.project3_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true   # EC2 gets a public IP automatically

  tags = {
    Name = "project3-subnet"
  }
}

# ── Route Table ───────────────────────────────────────────────────────────────
resource "aws_route_table" "project3_rt" {
  vpc_id = aws_vpc.project3_vpc.id

  route {
    cidr_block = "0.0.0.0/0"           # All traffic
    gateway_id = aws_internet_gateway.project3_igw.id
  }

  tags = {
    Name = "project3-rt"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "project3_rta" {
  subnet_id      = aws_subnet.project3_subnet.id
  route_table_id = aws_route_table.project3_rt.id
}

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "project3_sg" {
  name        = "project3-sg"
  description = "Allow SSH, HTTP, and ArgoCD access"
  vpc_id      = aws_vpc.project3_vpc.id

  # SSH — needed for Ansible and manual access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP — frontend web UI
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort range — Kubernetes NodePort services use 30000-32767
  ingress {
    description = "Kubernetes NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ArgoCD web UI
  ingress {
    description = "ArgoCD"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project3-sg"
  }
}

# ── EC2 Instance ──────────────────────────────────────────────────────────────
resource "aws_instance" "project3_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.project3_subnet.id
  vpc_security_group_ids = [aws_security_group.project3_sg.id]
  key_name               = aws_key_pair.project3.key_name

  # 20 GB root disk — microk8s and container images need space
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "project3-ec2"
  }
}

