provider "aws" {
  region = var.default_region
}


// controller instance

resource "aws_instance" "controller" {
    ami = var.controller_ami_id
    instance_type = var.controller_instance_type
    key_name      = var.ssh_key_name
    vpc_security_group_ids = [aws_security_group.controller_sg.id]
    associate_public_ip_address = var.associate_public_ip

    tags = {
        Name = var.controller_name
    }
}



// To fetch my ip address

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}



// controller sg

resource "aws_security_group" "controller_sg" {
  name = var.sg_name
  description = var.sg_description

  ingress {
    description = "Allow port 22 from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidrs]
  }
}