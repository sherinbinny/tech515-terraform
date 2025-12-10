provider "aws" {
    region = var.default_region
}


// db vm
resource "aws_instance" "db_instance" {
    ami = var.db_ami_id
    instance_type = var.db_instance_type
    key_name      = var.ssh_key_name
    vpc_security_group_ids = [aws_security_group.db_sg.id]
    associate_public_ip_address = var.associate_public_ip    

    tags = {
        Name = var.db_name
    }
}


// app vm
resource "aws_instance" "app_instance" {
    ami = var.app_ami_id
    instance_type = var.app_instance_type
    key_name      = var.ssh_key_name
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


// app sg
resource "aws_security_group" "app_sg" {
  name = var.sg_name
  description = var.sg_description
  vpc_id = data.aws_vpc.default.id

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



// db sg
resource "aws_security_group" "db_sg" {
  name = var.db_sg_name
  description = var.db_sg_description
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "Allow port 22 from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_cidr]
  }

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