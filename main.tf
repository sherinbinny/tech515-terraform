# create an EC2 instance
# cloud provider is AWS
provider "aws" {
    # use Ireland region
    region = "eu-west-1"
}

# which AMI ID ami-0c1c30571d2dae5c9 (for ubuntu 22.04 lts)
# type of instance t3.micro
# need a public IP address
# aws_access_key = asdadsfdg MUST NOT DO THIS
# aws_secret_key = asdadsfdg MUST NOT DO THIS
# name the instance tech515-sherin-tf-first-instance
# syntax for HCL is {key = value}
 
# which service/resource
resource "aws_instance" "app_instance" {
 
    # which AMI ID ami-0c1c30571d2dae5c9 (for ubuntu 22.04 lts)
    ami = "ami-0c1c30571d2dae5c9"
 
    # what type of instance to launch
    instance_type = "t3.micro"

    # SSH key to attach
    # This is immutable: once an EC2 is created, key_name cannot be changed via Terraform
    # Assigning key at creation ensures secure access
    key_name      = "tech515-sherin-aws"  # ← attach your SSH keypair here

    # Security groups to associate with this instance
    # Must reference IDs; we use the security group created already
    vpc_security_group_ids = [aws_security_group.web-sg.id]

    # please add a public ip to this instance
    associate_public_ip_address = true
 
    # name the service
    tags = {
        Name = "tech515-sherin-tf-second-instance"
    }
}


# Variable to store your current public IPv4 address
# This is used to restrict SSH access (port 22) to your machine only
# /32 ensures only your IP can access, which is a best practice for security

variable "my_ip" {
  default = "140.228.80.5/32"
}


# Fetch the default VPC for this AWS account/region
# Needed because Security Groups must belong to a VPC
# Using `data` allows Terraform to reference an existing resource instead of creating a new one

data "aws_vpc" "default" {
  default = true
}


# Create a security group for the EC2 instance
# A security group acts as a virtual firewall to control inbound and outbound traffic

resource "aws_security_group" "web-sg" {
  # Name of the security group
  name = "tech515-sherin-tf-allow-port-22-3000-80"
  # Description of the security group’s purpose
  description = "Allow SSH from my IP, allow port 3000 & 80 from all"
  # Associate this security group with the default VPC
  vpc_id = data.aws_vpc.default.id


  # Rule 1: SSH (port 22) from only your public IP
  # Limiting SSH access is critical for security to prevent unauthorized login attempts
  ingress {
    description = "Allow port 22 from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # uses variable to allow easy IP updates
  }


  # Rule 2: Port 3000 open to all
  # Useful if running a local development server or custom web app on port 3000
  ingress {
    description = "Allow port 3000 from all"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allows access from anywhere
  }

  # Rule 3: HTTP (port 80) open to all
  # Standard port for web traffic
  ingress {
    description = "Allow port 80 from all"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allows access from anywhere
  }

  # Allow all outbound traffic
  # By default, EC2 instances can reach the internet and other resources
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
