provider "aws" {
    region = var.default_region
}


# VPC

resource "aws_vpc" "custom_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}


# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = var.igw_name
  }
}


# Public Subnet for App

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.custom_vpc.id
  cidr_block = var.public_subnet_cidr
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = var.public_subnet_name
  }
}


# Private Subnet for DB

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.custom_vpc.id
  cidr_block = var.private_subnet_cidr

  tags = {
    Name = var.private_subnet_name
  }
}

# Route Table + Route + Association (Public)

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = var.route_cidr
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.public_rt_name
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


// DB instance

resource "aws_instance" "db_instance" {
    ami = var.db_ami_id
    instance_type = var.db_instance_type
    key_name      = var.ssh_key_name
    subnet_id = aws_subnet.private_subnet.id
    vpc_security_group_ids = [aws_security_group.db_sg.id]
    associate_public_ip_address = var.db_associate_public_ip    

    tags = {
        Name = var.db_name
    }
}


// App instance

resource "aws_instance" "app_instance" {
    ami = var.app_ami_id
    instance_type = var.app_instance_type
    key_name      = var.ssh_key_name
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.app_sg.id]
    associate_public_ip_address = var.associate_public_ip

    user_data = <<-EOF
      #! /bin/bash
      export DB_HOST=mongodb://${aws_instance.db_instance.private_ip}:27017/posts
      cd /home/ubuntu/tech515-sparta-app/app
      pm2 start app.js
    EOF
    

    tags = {
        Name = var.app_name
        Environment = var.environment
    }

    depends_on = [aws_instance.db_instance]
}





data "aws_vpc" "default" {
  default = true
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}


// App Security Group

resource "aws_security_group" "app_sg" {
  name = var.sg_name
  description = var.sg_description
  vpc_id = aws_vpc.custom_vpc.id

  ingress {
    description = "Allow port 22 from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_cidr]
  }

  ingress {
    description = "Allow port 3000 from all"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.port_3000_cidrs]
  }

  ingress {
    description = "Allow port 80 from all"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.port_80_cidrs]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidrs]
  }
}



// DB Security Group

resource "aws_security_group" "db_sg" {
  name = var.db_sg_name
  description = var.db_sg_description
  vpc_id = aws_vpc.custom_vpc.id

# Allow app VM to connect to database port
  ingress {
    description = "Allow MongoDB connections"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.port_27017_cidrs]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidrs]
  }
}