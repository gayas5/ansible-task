provider "aws" {
  region = "us-east-1"
}

variable "key_name" {
  default = "ansible"
}

}

variable "jenkins_allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

# ---------------------------
# Default VPC & Subnet
# ---------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------------------------
# Security Group
# ---------------------------
resource "aws_security_group" "app_sg" {
  name        = "ansible-app-sg"
  description = "Allow SSH, HTTP, Netdata"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.jenkins_allowed_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 19999
    to_port     = 19999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# Backend - Ubuntu
# ---------------------------
resource "aws_instance" "backend" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = { Name = "u21.local" }

  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname u21.local
EOF
}

# ---------------------------
# Frontend - Amazon Linux
# ---------------------------
resource "aws_instance" "frontend" {
  ami                    = "ami-068c0051b15cdb816"
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = { Name = "c8.local" }

  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname c8.local
echo "${aws_instance.backend.private_ip} backend.local" >> /etc/hosts
EOF

  depends_on = [aws_instance.backend]
}

# ---------------------------
# Inventory
# ---------------------------
resource "local_file" "inventory" {
  filename = "${path.module}/inventory.yaml"

  content = <<EOF
[frontend]
${aws_instance.frontend.public_ip} ansible_user=ec2-user

[backend]
${aws_instance.backend.public_ip} ansible_user=ubuntu
EOF
}

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}
