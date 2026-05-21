# --- Provider ---
provider "aws" {
  region = var.aws_region
}

# --- Security Group ---
resource "aws_security_group" "web_sg" {
  name   = "web-sg-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "web-sg" 
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- EC2 Instances ---
resource "aws_instance" "web" {
  count           = 2
  ami             = "ami-0c02fb55956c7d316"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.web_sg.name]
  key_name        = "lab-key"
  
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y python3.11 docker git
    sudo ln -sf /usr/bin/python3.11 /usr/bin/python3
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker ec2-user
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  EOF
  
  tags = { 
    Name = "web-${count.index + 1}" 
  }
}

# --- Outputs ---
output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = aws_instance.web[*].private_ip
}

output "app_url_instance1" {
  description = "URL to access application on instance 1"
  value       = "http://${aws_instance.web[0].public_ip}"
}

output "app_url_instance2" {
  description = "URL to access application on instance 2"
  value       = "http://${aws_instance.web[1].public_ip}"
}
