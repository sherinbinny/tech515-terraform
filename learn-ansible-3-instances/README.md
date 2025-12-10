# Learn Ansible 3 Instances - Terraform Setup

This project sets up **three EC2 instances** on AWS using Terraform. The instances simulate a basic Ansible setup:

1. **Controller** – The Ansible controller node.
2. **App Node** – The target node that will eventually run the application.
3. **DB Node** – The target node that will eventually run the database.

All instances are created in the **default VPC** with a **public IP** and proper **security groups** for SSH and service-specific ports.

---

## **Folder Structure**

```
learn-ansible-3-instances/
├── controller/
│   ├── main.tf
│   └── outputs.tf
├── app-node/
│   ├── main.tf
│   └── outputs.tf
└── db-node/
    ├── main.tf
    └── outputs.tf
```

* Each folder contains Terraform code for creating the respective instance.
* `main.tf` – Contains the EC2 instance and security group configuration.
* `outputs.tf` – Outputs the public IP of the instance for easy SSH access.

---

## **Instance Specifications**

| Instance   | Name                                                 | Type     | Ports Open                | Key Pair           | Image            | User Data | Public IP |
| ---------- | ---------------------------------------------------- | -------- | ------------------------- | ------------------ | ---------------- | --------- | --------- |
| Controller | techxxx-yourname-ubuntu-2204-ansible-controller      | t3.micro | 22 (SSH)                  | Your usual AWS key | Ubuntu 22.04 LTS | None      | Yes       |
| App Node   | techxxx-yourname-ubuntu-2204-ansible-target-node-app | t3.micro | 22 (SSH), 80 (HTTP), 3000 | Same key as above  | Ubuntu 22.04 LTS | None      | Yes       |
| DB Node    | techxxx-yourname-ubuntu-2204-ansible-target-node-db  | t3.micro | 22 (SSH), 27017 (MongoDB) | Same key as above  | Ubuntu 22.04 LTS | None      | Yes       |

---

## **How It Works**

1. **Security Groups**

   * Each instance has a dedicated security group allowing required ports.
   * SSH access is enabled for all instances; service ports differ by instance.

2. **AMI Selection**

   * Uses the **latest Ubuntu 22.04 LTS AMI** dynamically via Terraform data source.
   * No custom AMIs or user-data scripts are used.

3. **Networking**

   * Instances are launched in the **default VPC and subnets**.
   * Each instance gets a **public IP** for SSH access.

---

## **Setup Instructions**

### **Step 1 – Initialize Terraform**

For each folder (`controller`, `app-node`, `db-node`):

```bash
cd <folder-name>
terraform init
```

---

### **Step 2 – Plan**

```bash
terraform plan
```

* Review the plan to ensure the resources will be created as expected.

---

### **Step 3 – Apply**

```bash
terraform apply
```

* Confirm the creation.
* Terraform will create the EC2 instance with the proper security group.

---

### **Step 4 – SSH Access**

Retrieve the public IP from Terraform output:

```bash
terraform output
```

SSH into the instance:

```bash
ssh -i ~/.ssh/your-usual-key.pem ubuntu@<public_ip>
```

---

### **Step 5 – Destroy Resources**

Once testing is done, destroy each instance to avoid AWS charges:

```bash
terraform destroy
```

---

## **Testing Checklist**

* [ ] Terraform successfully creates each EC2 instance.
* [ ] Can SSH into all three instances using the key pair.
* [ ] Security group rules allow access to the required ports.
* [ ] Public IP addresses are assigned and reachable.
* [ ] Instances can be destroyed cleanly with Terraform.
