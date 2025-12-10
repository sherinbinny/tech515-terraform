# **Terraform Deployment: Custom VPC with App & Database – Step-by-Step Guide**

This guide explains how to deploy a secure AWS VPC environment with **application and database EC2 instances**, using Terraform. Each step includes **why it’s needed** to help you understand the reasoning.

---

## **Step 1: Setup Terraform Provider**

```hcl
provider "aws" {
    region = var.default_region
}
```

**Why:**

* Terraform needs to know which cloud provider to use.
* `region` specifies where your resources will be created (e.g., `eu-west-1`).

---

## **Step 2: Create a Custom VPC**

```hcl
resource "aws_vpc" "custom_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}
```

**Why:**

* VPC isolates your resources from other AWS accounts.
* You define your IP address range with `cidr_block` (e.g., `10.0.0.0/16`).
* Tagging helps identify the VPC in the AWS console.

---

## **Step 3: Add an Internet Gateway**

```hcl
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = var.igw_name
  }
}
```

**Why:**

* Needed to allow internet access for public-facing resources (like your app server).
* Only public subnets routed through the IGW can reach the internet.

---

## **Step 4: Create Subnets**

### **Public Subnet (for App)**

```hcl
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = var.public_subnet_name
  }
}
```

**Why:**

* App servers need a **public IP** for internet access.
* `map_public_ip_on_launch = true` ensures EC2 gets a public IP automatically.

---

### **Private Subnet (for DB)**

```hcl
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.custom_vpc.id
  cidr_block = var.private_subnet_cidr

  tags = {
    Name = var.private_subnet_name
  }
}
```

**Why:**

* Database must **not be publicly accessible**.
* Private subnet ensures only internal resources (like app servers) can connect.

---

## **Step 5: Create Route Table and Associate**

```hcl
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
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
```

**Why:**

* Public subnet needs a **route to the IGW** to reach the internet.
* Private subnets don’t need this route (unless using NAT for outbound internet).

---

## **Step 6: Configure Security Groups**

### **App Security Group**

```hcl
resource "aws_security_group" "app_sg" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description = "Allow SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_cidr]
  }

  ingress {
    description = "Allow app port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.port_3000_cidrs]
  }

  ingress {
    description = "Allow HTTP port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.port_80_cidrs]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidrs]
  }
}
```

**Why:**

* SSH restricted to your IP for security.
* App ports open for clients to access the application.
* Egress allows outbound traffic (required for app to connect to DB, updates, etc.).

---

### **DB Security Group**

```hcl
resource "aws_security_group" "db_sg" {
  name        = var.db_sg_name
  description = var.db_sg_description
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description     = "Allow MongoDB connections from App SG"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [var.port_27017_cidrs]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidrs]
  }
}
```

**Why:**

* DB is **private**. Only app servers can access MongoDB port.
* Prevents exposure to the internet.

---

## **Step 7: Launch EC2 Instances**

### **Database Instance (Private Subnet)**

```hcl
resource "aws_instance" "db_instance" {
  ami                         = var.db_ami_id
  instance_type               = var.db_instance_type
  key_name                     = var.ssh_key_name
  subnet_id                    = aws_subnet.private_subnet.id
  vpc_security_group_ids       = [aws_security_group.db_sg.id]
  associate_public_ip_address  = var.db_associate_public_ip

  tags = {
    Name = var.db_name
  }
}
```

**Why:**

* Launched in **private subnet**, no public IP.
* Security group ensures **only app servers can connect**.

---

### **App Instance (Public Subnet)**

```hcl
resource "aws_instance" "app_instance" {
  ami                         = var.app_ami_id
  instance_type               = var.app_instance_type
  key_name                     = var.ssh_key_name
  subnet_id                    = aws_subnet.public_subnet.id
  vpc_security_group_ids       = [aws_security_group.app_sg.id]
  associate_public_ip_address  = var.associate_public_ip

  user_data = <<-EOF
    #! /bin/bash
    export DB_HOST=mongodb://${aws_instance.db_instance.private_ip}:27017/posts
    cd /home/ubuntu/tech515-sparta-app/app
    pm2 start app.js
  EOF

  tags = {
    Name        = var.app_name
    Environment = var.environment
  }

  depends_on = [aws_instance.db_instance]
}
```

**Why:**

* Public subnet allows app server to be accessed from the internet.
* `user_data` automatically connects the app to the DB on launch.
* `depends_on` ensures DB instance is ready before the app starts.
