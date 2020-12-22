# The father of everything here
provider "aws" {
    region = "ap-southeast-2"
}

# Define a VPC, which enables launchong AWS resources into a virtual network that i've defined
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "prod"
  }
}

# Define internet gateway for the VPC to allow access to the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "main"
  }
}

# Create a Route Table that directs internet-bound traffic to the internet gateway

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# A VPC aint nothing without its subnets
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"
}

resource "aws_subnet" "subnet-2" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-southeast-2b"
}

# Define a security group, which acts as a virtual firewall for my instance to control inbound and outbound traffic
resource "aws_security_group" "allow_web" {
   name        = "allow_web_traffic"
   description = "Allow Web inbound traffic"
   vpc_id      = aws_vpc.prod-vpc.id

   ingress {
     description = "HTTPS"
     from_port   = 443
     to_port     = 443
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "HTTP"
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "SSH"
     from_port   = 22
     to_port     = 22
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
     Name = "allow_web"
   }
 }