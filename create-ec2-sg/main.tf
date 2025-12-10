# create an EC2 instance
# cloud provider is AWS
provider "aws" {
    # use Ireland region
    region = var.default_region
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
    ami = var.app_ami_id
 
    # what type of instance to launch
    instance_type = var.app_instance_type

    # SSH key to attach
    # This is immutable: once an EC2 is created, key_name cannot be changed via Terraform
    # Assigning key at creation ensures secure access
    key_name      = var.ssh_key_name  # ← attach your SSH keypair here

    # Security groups to associate with this instance
    # Must reference IDs; we use the security group created already
    vpc_security_group_ids = [aws_security_group.app-sg.id]

    # please add a public ip to this instance
    associate_public_ip_address = var.associate_public_ip
 
    # name the service
    tags = {
        Name = var.app_name
        Environment = var.environment
    }
}




# Fetch the default VPC for this AWS account/region
# Needed because Security Groups must belong to a VPC
# Using `data` allows Terraform to reference an existing resource instead of creating a new one
data "aws_vpc" "default" {
  default = true
}



# Terraform uses this URL to detect the IP address
# of the machine running `terraform apply`.
# This eliminates the need to manually look up your IP.
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

# checkip returns something like "81.103.221.52\n"
# chomp() removes the newline so Terraform doesn’t break.
# We append /32 to restrict SSH access to exactly one IP.
locals {
  my_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

# Create a security group for the EC2 instance
# A security group acts as a virtual firewall to control inbound and outbound traffic

resource "aws_security_group" "app-sg" {
  # Name of the security group
  name = var.sg_name
  # Description of the security group’s purpose
  description = var.sg_description
  # Associate this security group with the default VPC
  vpc_id = data.aws_vpc.default.id


  # Rule 1: SSH (port 22) from only your public IP
  # Limiting SSH access is critical for security to prevent unauthorized login attempts
  ingress {
    description = "Allow port 22 from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_cidr] # uses variable to allow easy IP updates
  }


  # Rule 2: Port 3000 open to all
  # Useful if running a local development server or custom web app on port 3000
  ingress {
    description = "Allow port 3000 from all"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.port_3000_cidrs] # allows access from anywhere
  }

  # Rule 3: HTTP (port 80) open to all
  # Standard port for web traffic
  ingress {
    description = "Allow port 80 from all"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.port_80_cidrs] # allows access from anywhere
  }

  # Allow all outbound traffic
  # By default, EC2 instances can reach the internet and other resources
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidrs]
  }
}
