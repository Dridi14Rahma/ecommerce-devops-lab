# --- Provider ---
provider "aws" {
  region = var.aws_region
}

# --- EC2 Instances ---
resource "aws_instance" "web" {
  count              = 2
  ami                = "ami-0c02fb55956c7d316"
  instance_type      = "t3.micro"
  key_name           = "lab-key"
  
  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    set -e
    exec > >(tee /var/log/user-data.log)
    exec 2>&1
    
    echo "=== Starting user_data script ==="
    
    # Basic system prep (minimal)
    echo "Installing basic tools..."
    yum install -y wget curl git 2>/dev/null || true
    
    # Install Python 3.11 from amazon-linux-extras if available
    echo "Installing Python 3.11..."
    yum install -y python3.11 2>/dev/null || {
      amazon-linux-extras install -y python3.11 2>/dev/null || true
    }
    
    # Create symlink if Python 3.11 exists
    if [ -f /usr/bin/python3.11 ]; then
      ln -sf /usr/bin/python3.11 /usr/bin/python3 || true
    fi
    
    # Install Docker (non-blocking)
    echo "Installing Docker..."
    yum install -y docker 2>/dev/null || {
      echo "Docker installation failed, continuing..."
    }
    
    # Start Docker if installed
    if command -v docker &> /dev/null; then
      systemctl start docker 2>/dev/null || true
      systemctl enable docker 2>/dev/null || true
    fi
    
    # Install Docker Compose (non-blocking)
    echo "Installing Docker Compose..."
    if command -v docker &> /dev/null; then
      mkdir -p /usr/local/bin
      DOCKER_CONFIG=$${DOCKER_CONFIG:-$$HOME/.docker}
      mkdir -p $$DOCKER_CONFIG/cli-plugins
      curl -sSL https://github.com/docker/compose/releases/latest/download/docker-compose-$$(uname -s)-$$(uname -m) -o /usr/local/bin/docker-compose 2>/dev/null || {
        curl -sSL https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$$(uname -s)-$$(uname -m) -o /usr/local/bin/docker-compose 2>/dev/null || true
      }
      chmod +x /usr/local/bin/docker-compose 2>/dev/null || true
    fi
    
    # Add ec2-user to docker group
    if grep -q docker /etc/group; then
      usermod -a -G docker ec2-user 2>/dev/null || true
    fi
    
    echo "=== user_data script complete ==="
  EOF
  )
  
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
