# Define variables
variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr_block" {
  default = "10.0.2.0/24"
}

variable "ami_id" {
  default = "ami-005f9685cb30f234b" # Amazon Linux 2 AMI
}

# Create VPC
resource "aws_vpc" "example_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "example_vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id

  tags = {
    Name = "example_igw"
  }
}


# Create Public Subnet
resource "aws_subnet" "example_public_subnet" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "example_public_subnet"
  }
}

# Create Private Subnet
resource "aws_subnet" "example_private_subnet" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "example_private_subnet"
  }
}

resource "aws_route" "route_internet" {
  route_table_id = aws_vpc.example_vpc.default_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.example_igw.id
}


# Create Security Group for Apache Web Server
resource "aws_security_group" "example_webserver_sg" {
  name_prefix = "example_webserver_sg"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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

# Create Apache Web Server instance in Public Subnet
resource "aws_instance" "example_webserver_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.example_public_subnet.id
  vpc_security_group_ids = [aws_security_group.example_webserver_sg.id]
  associate_public_ip_address = true
  iam_instance_profile = "LabInstanceProfile"
  user_data = <<-EOF
		#!/bin/bash
              yum update -y
              yum install -y httpd
              echo "Hello World!" > /var/www/html/index.html
              service httpd start
              chkconfig httpd on
              EOF


  tags = {
    Name = "example_webserver_instance"
  }
}

# Output
