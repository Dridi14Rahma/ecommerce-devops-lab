# --- Provider ---
provider "aws" {
  region = var.aws_region
}

# --- EC2 Instances ---
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  key_name      = "lab-key"
  
  # NO user_data - let instances boot cleanly without any script execution
  # Amazon Linux 2 has Python 3.7 by default - Ansible will use it
  
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
