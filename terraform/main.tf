# --- Provider ---
provider "aws" {
  region = var.aws_region
}

# --- Security Group (uses default VPC automatically) ---
resource "aws_security_group" "web_sg" {
  name   = "web-sg-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTP (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS (port 443)
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

# --- EC2 Instances (on default VPC) ---
resource "aws_instance" "web" {
  count           = 2
  ami             = "ami-0c02fb55956c7d316"  # Amazon Linux 2
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

# --- Security Group for ALB ---
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
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
    Name = "alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- Application Load Balancer (on default VPC) ---
resource "aws_lb" "app" {
  name               = "app-lb-${formatdate("hhmm", timestamp())}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  
  enable_deletion_protection = false
  tags = {
    Name = "app-alb"
  }
}

# --- Target Group ---
resource "aws_lb_target_group" "app" {
  name        = "app-tg-${formatdate("hhmm", timestamp())}"
  port        = 80
  protocol    = "HTTP"
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
  
  tags = {
    Name = "app-tg"
  }
}

# --- Target Group Attachment ---
resource "aws_lb_target_group_attachment" "app" {
  count            = 2
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# --- ALB Listener ---
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
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

output "alb_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "app_url" {
  description = "URL to access the application through load balancer"
  value       = "http://${aws_lb.app.dns_name}"
}
}
