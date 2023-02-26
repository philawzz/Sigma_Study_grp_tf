

provider "aws" {
  region = "eu-west-2"
}


# Create the production vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "production-VPC"
  }
}


# Create the production subnet
resource "aws_subnet" "prod-subnet" {
  vpc_id                  = aws_vpc.prod-vpc.id
  availability_zone       = "eu-west-2a"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "production subnet"
  }
}

# Create Internet gateway
resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.prod-vpc.id
}


# Create route table
resource "aws_route_table" "prod-rt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-igw.id
  }
  tags = {
    Name = "Prod-RT"
  }
}


# Associates subnet with Route Table
resource "aws_route_table_association" "rt-a" {
  subnet_id      = aws_subnet.prod-subnet.id
  route_table_id = aws_route_table.prod-rt.id
}


#Create Security Group to allow port 22,80,443
resource "aws_security_group" "prod-sg" {
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


resource "aws_instance" "prod-server" {
  subnet_id         = aws_subnet.prod-subnet.id
  ami               = "ami-0aaa5410833273cfe"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-2a"
  key_name          = "London02"


  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
  tags = {
    Name = "web-server"
  }

  # Security Group
  vpc_security_group_ids = [aws_security_group.prod-sg.id]
}


output "server-ip" {
  value = aws_instance.prod-server.public_ip
}