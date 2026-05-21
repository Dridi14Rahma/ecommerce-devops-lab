# --- Provider ---
provider "aws" {
  region = var.aws_region
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { 
    Name = "devops-vpc" 
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { 
    Name = "devops-igw" 
  }
}

# --- Public Subnet ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = { 
    Name = "devops-public-subnet" 
  }
}

# --- Route Table ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { 
    Name = "devops-rt" 
  }
}

# --- Route Table Association ---
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# --- Security Group ---
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id
  
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
}

# --- LabRole for Student Account ---
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_iam_instance_profile" "lab_profile" {
  name = "lab-instance-profile-v20"
  role = data.aws_iam_role.lab_role.name
}

# --- EC2 Instances ---
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c02fb55956c7d316"  # Amazon Linux 2
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name      = "lab-key"  # Utilisation directe du nom de la clé existante
  iam_instance_profile = aws_iam_instance_profile.lab_profile.name
  
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

# --- Application Load Balancer ---
resource "aws_lb" "app" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.private.id]
  
  enable_deletion_protection = false
  tags = {
    Name = "app-alb"
  }
}

# --- Security Group for ALB ---
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id
  
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
}

# --- Target Group ---
resource "aws_lb_target_group" "app" {
  name        = "app-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  
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

# --- Private Subnet for ALB ---
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "devops-private-subnet"
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
