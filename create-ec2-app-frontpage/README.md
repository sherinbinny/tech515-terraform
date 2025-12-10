# **Terraform App VM Deployment**

### **1️⃣ Prerequisites**

- AWS account with default VPC available
- Custom AMI built with Node.js, PM2, and your app (`tech515-sparta-app`) already present
- SSH key pair already created in AWS (`var.ssh_key_name`)
- Terraform installed locally
- Public IP of your local machine (fetched automatically via `https://checkip.amazonaws.com/`)

---

### **2️⃣ Terraform Project Structure**

Your Terraform folder contained:

```
.
├── main.tf         # contains provider, EC2 instance, security group, user_data
├── variables.tf    # all input variables (AMI, instance type, key, etc.)
└── outputs.tf      # outputs like public IP and app URL
```

---

### **3️⃣ Define the AWS Provider**

```hcl
provider "aws" {
    region = var.default_region
}
```

- Ensures Terraform knows which AWS region to deploy resources in.
- Region variable is defined in `variables.tf`.

---

### **4️⃣ Get Current Public IP**

```hcl
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}
```

- Automatically fetches your current public IP.
- Converts it to CIDR format (`x.x.x.x/32`) for the security group.
- Ensures SSH access is restricted to your machine only.

---

### **5️⃣ Create the Security Group**

```hcl
resource "aws_security_group" "app_sg" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow port 22 from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_cidr]
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

- Allows HTTP (port 80) from anywhere.
- Allows SSH (port 22) from your IP only.
- Outbound is fully open for simplicity.
- Linked to default VPC.

---

### **6️⃣ Deploy the App VM**

```hcl
resource "aws_instance" "app_instance" {
    ami                         = var.app_ami_id
    instance_type               = var.app_instance_type
    key_name                    = var.ssh_key_name
    vpc_security_group_ids      = [aws_security_group.app_sg.id]
    associate_public_ip_address = var.associate_public_ip

    user_data = <<-EOF
      #! /bin/bash
      sudo apt update
      cd /home/ubuntu/tech515-sparta-app/app
      pm2 start app.js
      pm2 save
    EOF

    tags = {
        Name        = var.app_name
        Environment = var.environment
    }
}
```

**Notes:**

- EC2 instance uses your custom AMI.
- `user_data` ensures your app starts automatically using PM2.
- Public IP assigned so front page is accessible.
- Security group applied for SSH and HTTP access.

---

### **7️⃣ Steps to Deploy**

1. Initialize Terraform:

```bash
terraform init
```

2. Plan the deployment (review changes):

```bash
terraform plan \
  -var="default_region=eu-west-1" \
  -var="app_ami_id=ami-xxxxxx" \
  -var="app_instance_type=t3.micro" \
  -var="ssh_key_name=my-key" \
  -var="associate_public_ip=true" \
  -var="sg_name=app-sg" \
  -var="sg_description=App Security Group" \
  -var="port_80_cidrs=0.0.0.0/0" \
  -var="egress_cidrs=0.0.0.0/0" \
  -var="app_name=tech515-app" \
  -var="environment=dev"
```

3. Apply the deployment:

```bash
terraform apply -auto-approve \
  -var="..."   # same vars as plan
```

- Terraform creates the security group and EC2 instance automatically.
- `user_data` runs and starts your app on the instance.

---

### **8️⃣ Test Deployment**

1. **SSH into the VM**

```bash
ssh -i mykey.pem ubuntu@<public-ip>
```

- Confirms SSH access works.
- Verify PM2 is running:

```bash
pm2 list
```

2. **Open the front page**

- Browser URL: `http://<public-ip>`
- Should display your app.

---

### **9️⃣ Outputs (Optional)**

Add to `outputs.tf` for convenience:

```hcl
output "app_public_ip" {
  value = aws_instance.app_instance.public_ip
}

output "app_url" {
  value = "http://${aws_instance.app_instance.public_ip}"
}
```

- Immediately know the URL after `terraform apply`.

---

### **10️⃣ Key Points / Lessons Learned**

- Always reference resources without dashes (`aws_security_group.app_sg.id` not `app-sg`).
- Restrict SSH to your own IP — security first.
- Make sure the custom AMI has Node, PM2, and app ready — user_data can only start services.
- Assign a public IP if you need public access.
- Testing SSH and front page is the final validation step.

---

### ✅ **Deliverable**

Once verified:

```
http://<public-ip>
Terraform deployed app
```
