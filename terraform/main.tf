provider "aws" {
region = var.aws_region
}
# --- VPC ---
resource "aws_vpc" "main" {
cidr_block = "10.0.0.0/16"
enable_dns_hostnames = true
tags = { Name = "devops-vpc" }
}
# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
vpc_id = aws_vpc.main.id
tags = { Name = "devops-igw" }
}
# --- Public Subnet ---
resource "aws_subnet" "public" {
vpc_id = aws_vpc.main.id
cidr_block = "10.0.1.0/24"
map_public_ip_on_launch = true
availability_zone = "us-east-1a"
tags = { Name = "devops-public-subnet" }
}
# --- Route Table ---
resource "aws_route_table" "public_rt" {
vpc_id = aws_vpc.main.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw.id
}
tags = { Name = "devops-rt" }
}
resource "aws_route_table_association" "rta" {
subnet_id = aws_subnet.public.id
route_table_id = aws_route_table.public_rt.id
}
# --- Security Group ---
resource "aws_security_group" "web_sg" {
name = "web-sg"
vpc_id = aws_vpc.main.id
ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
<<<<<<< HEAD

# ─── Key Pair SSH ─────────────────────────────────────────
variable "public_key" {
  type = string
}
resource "aws_key_pair" "deployer" {
  key_name   = "ecommerce-key"
  public_key = var.public_key
=======
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
>>>>>>> 72d46fa (Initial full pipeline)
}
tags = { Name = "web-sg" }
}
# --- LabRole for Student Account ---
data "aws_iam_role" "lab_role" {
name = "LabRole"
}
resource "aws_iam_instance_profile" "lab_profile" {
name = "lab-instance-profile"
role = data.aws_iam_role.lab_role.name
}
# --- EC2 Instances ---
resource "aws_instance" "web" {
count = 2
ami = "ami-0c02fb55956c7d316" # Amazon Linux 2
instance_type = "t3.micro"
subnet_id = aws_subnet.public.id
vpc_security_group_ids = [aws_security_group.web_sg.id]
key_name = var.key_name
iam_instance_profile = aws_iam_instance_profile.lab_profile.name
tags = { Name = "web-${count.index + 1}" }
}
# --- Output IPs (used by Ansible) ---
output "instance_public_ips" {
value = aws_instance.web[*].public_ip
}
