provider "aws" {
  region = var.default_region
}


// DB instance

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



// To fetch my ip address

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}



// db sg

resource "aws_security_group" "db_sg" {
  name = var.db_sg_name
  description = var.db_sg_description

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