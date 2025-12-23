provider "aws" {
  region = var.default_region
}


// App instance

resource "aws_instance" "app_instance" {
    ami = var.app_ami_id
    instance_type = var.app_instance_type
    key_name      = var.ssh_key_name
    vpc_security_group_ids = [aws_security_group.app_sg.id]
    associate_public_ip_address = var.associate_public_ip

    tags = {
        Name = var.app_name
    }
}



// To fetch my ip address

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

  ingress {
    description = "Allow port 22 from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.port_22_cidrs]
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