# Terraform AWS EC2 Setup – tech515-sherin-tf

This project demonstrates how to provision an **AWS EC2 instance** using **Terraform**, along with a **custom security group** to control access to SSH, HTTP, and a custom port.

---

## **Cloud Provider**

* **Provider:** AWS
* **Region:** Ireland (`eu-west-1`)
* **Access Keys:** Managed via environment variables or AWS CLI configuration. **Do NOT hardcode keys in Terraform.**

---

## **Resources Created**

### **1. Security Group**

* **Name:** `tech515-sherin-tf-allow-port-22-3000-80`
* **Description:** Allows:

  * SSH (port 22) only from your IP address
  * Port 3000 from all
  * HTTP (port 80) from all
* **Rules:**

```hcl
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [var.my_ip]      # Your current public IPv4
}

ingress {
  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

* **VPC:** Default VPC in the selected region

---

### **2. EC2 Instance**

* **Name:** `tech515-sherin-tf-second-instance`
* **AMI:** `ami-0c1c30571d2dae5c9` (Ubuntu 22.04 LTS)
* **Instance Type:** `t3.micro`
* **Public IP:** Enabled (`associate_public_ip_address = true`)
* **Security Group:** Attached `tech515-sherin-tf-allow-port-22-3000-80`
* **SSH Key:** `tech515-sherin-aws`

```hcl
resource "aws_instance" "app_instance" {
  ami                         = "ami-0c1c30571d2dae5c9"
  instance_type               = "t3.micro"
  key_name                    = "tech515-sherin-aws"
  vpc_security_group_ids      = [aws_security_group.web-sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "tech515-sherin-tf-second-instance"
  }
}
```

---

## **Variables**

* **`my_ip`** – Your current public IPv4 address for SSH access.

```hcl
variable "my_ip" {
  default = "140.228.80.5/32"
}
```

> ⚠ Make sure to update this if your public IP changes.

---

## **Terraform Workflow**

### **1. Initialize Terraform**

```bash
terraform init
```

### **2. Plan Changes**

```bash
terraform plan
```

* Review what resources will be created, updated, or destroyed.

### **3. Apply Changes**

```bash
terraform apply
```

* Confirm with `yes` when prompted.
* Terraform will create the security group and EC2 instance.

### **4. Check EC2 Public IP**

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tech515-sherin-tf-second-instance" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text
```

### **5. SSH into Instance**

```bash
ssh -i "tech515-sherin-aws.pem" ubuntu@ec2-34-245-171-243.eu-west-1.compute.amazonaws.com
```