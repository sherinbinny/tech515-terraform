# **Terraform Deployment Documentation: App & Database VM**

## **1. Overview**

This Terraform configuration automates the deployment of two EC2 instances on AWS:

1. **App VM** – Hosts a Node.js application. The front page is served on port 80/3000.
2. **Database VM** – Hosts MongoDB. The Node.js app connects to this VM via its private IP to serve `/posts`.

Key features:

* Security Groups are restricted to necessary ports.
* Private IP used for app → DB communication for security.
* Public IP available for SSH and app testing.
* User data script automates app start via PM2.

---

## **2. Terraform Provider**

```hcl
provider "aws" {
    region = var.default_region
}
```

* **AWS Provider**: All resources are deployed in the region specified by `var.default_region`.

---

## **3. Data Sources & Locals**

```hcl
data "aws_vpc" "default" {
  default = true
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}
```

* **VPC**: Uses the default VPC.
* **Current Public IP**: Captured to restrict SSH access to the user’s IP.
* **Local Variable `my_cidr`**: Used in security groups for SSH restriction.

---

## **4. Security Groups**

### **4.1 App Security Group (`app_sg`)**

* Allows:

  * SSH (port 22) from the user’s IP only.
  * Node.js app port (3000) from all (optional).
  * HTTP (port 80) from all.
* Egress: Allows all outbound traffic.

```hcl
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
```

---

### **4.2 Database Security Group (`db_sg`)**

* Allows:

  * SSH (port 22) from user’s IP only.
  * MongoDB (port 27017) **only from the App VM**.
* Egress: All outbound traffic allowed.

```hcl
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

  ingress {
    description = "Allow MongoDB connections from app VM"
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
```

---

## **5. EC2 Instances**

### **5.1 Database VM**

```hcl
resource "aws_instance" "db_instance" {
    ami = var.db_ami_id
    instance_type = var.db_instance_type
    key_name = var.ssh_key_name
    vpc_security_group_ids = [aws_security_group.db_sg.id]
    associate_public_ip_address = var.associate_public_ip    

    tags = {
        Name = var.db_name
    }
}
```

* **Custom AMI**: MongoDB pre-installed.
* **Security Group**: `db_sg`.
* **SSH Access**: Restricted to user’s IP.

---

### **5.2 App VM**

```hcl
resource "aws_instance" "app_instance" {
    ami = var.app_ami_id
    instance_type = var.app_instance_type
    key_name = var.ssh_key_name
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
```

* **Custom AMI**: Node.js + PM2 pre-installed.
* **DB Connection**: `DB_HOST` set dynamically using database VM private IP.
* **Dependency**: App waits until DB VM is created (`depends_on`).

---

## **6. Deployment Steps**

1. **Initialize Terraform**

```bash
terraform init
```

2. **Validate Configuration**

```bash
terraform validate
```

3. **Preview Changes**

```bash
terraform plan
```

4. **Apply Changes**

```bash
terraform apply -auto-approve
```

5. **Verify**

* Front page: `http://<APP_PUBLIC_IP>/`
* Posts page: `http://<APP_PUBLIC_IP>/posts`
