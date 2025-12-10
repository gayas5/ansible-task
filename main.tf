provider "aws" {
  region = "ap-south-1"
}

# ---------------------------
# Backend - Ubuntu
# ---------------------------
resource "aws_instance" "backend" {
  ami                    = "ami-02b8269d5e85954ef"  
  instance_type          = "t3.micro"
  key_name               = "mumbai"
  vpc_security_group_ids = ["sg-01cfc6e86d017a57b"]
  subnet_id              = "subnet-0491ca8b1885b7e5e"

  tags = {
    Name = "u21.local"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo hostnamectl set-hostname u21.local
  EOF
}

# ---------------------------
# Frontend - Amazon Linux
# ---------------------------
resource "aws_instance" "frontend" {
  ami                    = "ami-0d176f79571d18a8f"   # Amazon Linux
  instance_type          = "t3.micro"
  key_name               = "mumbai"
  vpc_security_group_ids = ["sg-01cfc6e86d017a57b"]
  subnet_id              = "subnet-04f01a3277f9dd175"

  tags = {
    Name = "c8.local"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo hostnamectl set-hostname c8.local

    hostname=$(hostname)
    backend_ip="${aws_instance.backend.public_ip}"

    echo "$backend_ip $hostname" | sudo tee -a /etc/hosts
  EOF

  depends_on = [aws_instance.backend]
}

# ---------------------------
# Inventory file
# ---------------------------
resource "local_file" "inventory" {
  filename = "./inventory.yaml"

  content = <<EOF
[frontend]
${aws_instance.frontend.public_ip}

[backend]
${aws_instance.backend.public_ip}
EOF
}

# ---------------------------
# Outputs
# ---------------------------
output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}
