# **Task: Deploy Different Environments Using Terraform (dev → 1 instance, prod → 2 instances)**

### **Goal**

Use Terraform to deploy a variable number of app instances based on the chosen environment.

* `dev` → **1 instance**
* `prod` → **2 instances**
  You must keep the code DRY and organise each approach into its own folder (e.g., `/method-1`, `/method-2`, `/method-3`).
  Do **not** create separate folders for each environment.

---

# **✔ Method 1 — Use `count` + mapping (simple & clean)**

This is the most straightforward, enterprise-friendly approach. It uses a variable for environment + a map that converts environment → #instances. No repetition. Just solid execution.

### **Folder: `method-1/`**

### **variables.tf**

```hcl
variable "environment" {
  type = string
  description = "Environment to deploy: dev or prod"
}

variable "instance_count_map" {
  type = map(number)
  default = {
    dev  = 1
    prod = 2
  }
}
```

### **main.tf**

```hcl
locals {
  instance_count = var.instance_count_map[var.environment]
}

resource "aws_instance" "app" {
  count         = local.instance_count
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = {
    Name = "app-${var.environment}-${count.index}"
  }
}
```

### **How it works**

* User passes `-var="environment=dev"` or `prod`.
* A map converts environment → number of instances.
* `count` creates the correct number of EC2s.
* Fully DRY because everything is parameterised.

**Pros:** Easiest to understand, rock solid.
**Cons:** `count` limits flexibility for individual resource modifications.

---

# **✔ Method 2 — Use `for_each` with dynamic map generation**

This method takes a more modern, scalable approach using `for_each`.
Cleaner naming, easier lifecycle targeting, more flexibility.

### **Folder: `method-2/`**

### **variables.tf**

```hcl
variable "environment" {
  type = string
}
```

### **main.tf**

```hcl
locals {
  instance_count = var.environment == "prod" ? 2 : 1

  instances = {
    for num in range(local.instance_count) :
    "app-${var.environment}-${num}" => num
  }
}

resource "aws_instance" "app" {
  for_each      = local.instances
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = {
    Name = each.key
  }
}
```

### **How it works**

* Terraform evaluates environment → outputs number (1 or 2).
* A `for` expression turns that into a map of instance names.
* `for_each` loops over the map and deploys an EC2 per key.

**Pros:**

* Predictable naming (`app-prod-0`, `app-prod-1`)
* Easier to remove/replace specific instances
* Preferred in modern Terraform

**Cons:** Slightly more complex for newcomers.

---

# **✔ Method 3 — Using Terraform modules + input variable override**

This method lets you scale massively as an organisation grows.
One reusable module that accepts `instance_count`.
The root module decides dev vs prod.

### **Folder: `method-3/`**

Structure:

```
method-3/
  main.tf
  variables.tf
  modules/
    app/
      main.tf
      variables.tf
```

### **modules/app/variables.tf**

```hcl
variable "instance_count" {
  type = number
}
```

### **modules/app/main.tf**

```hcl
resource "aws_instance" "app" {
  count         = var.instance_count
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = {
    Name = "app-instance-${count.index}"
  }
}
```

### **root variables.tf**

```hcl
variable "environment" {
  type = string
}
```

### **root main.tf**

```hcl
locals {
  instance_count = var.environment == "prod" ? 2 : 1
}

module "app" {
  source         = "./modules/app"
  instance_count = local.instance_count
}
```

### **How it works**

* The root module decides: one instance or two.
* The logic is kept out of the module → DRY.
* The module stays reusable for dozens of teams.

**Pros:**

* Real-world production pattern
* Clean separation of concerns
* Easy to scale, test, reuse

**Cons:** Slightly more files to manage.

---

# **How to run each method**

```bash
terraform init
terraform apply -var="environment=dev"
```

or

```bash
terraform apply -var="environment=prod"
```

---

# **Which method should YOU use?**

Since you're building your Terraform skills fast and want enterprise-ready workflows, I’d recommend:

🥇 **Method 2** — Modern, flexible, clean
🥈 **Method 1** — Perfect for beginners or smaller teams
🥉 **Method 3** — Best for long-term multi-team scaling



<br><br><br>












# 📘 **Terraform: Deploying Different Environments (dev → 1 instance, prod → 2 instances)**

### **Full Documentation – Strategy, Architecture, Implementation**

Your goal:
Build Terraform code that can deploy **different numbers of app instances** depending on the selected environment — *without duplicating code* or managing separate Terraform folders for dev vs prod.

This is a real-world architecture pattern. Companies run the same codebase across different environments but scale the infrastructure differently.

We will create **three different approaches**, each in its own folder:

```
method-1-count/
method-2-foreach/
method-3-modules/
```

Inside each, Terraform figures out the correct number of instances to create based on your variable:

* `environment = "dev"` → 1 instance
* `environment = "prod"` → 2 instances

This lets you stay DRY and align with real software engineering practices.

---

# ------------------------------------------------------------

# 🎯 **WHY WE NEED THESE PATTERNS**

---

Modern organisations need:

* Dev environments (cheap, lightweight, single instance)
* Prod environments (redundant, scaled-out, highly available)

But rewriting Terraform code per environment would violate the **DRY principle** and become a maintenance nightmare.

Thus, we need ONE Terraform architecture that dynamically adapts.

Terraform gives us three main levers to achieve this:

1. **`count` meta-argument**
2. **`for_each` meta-argument**
3. **Modules and variable-driven scaling**

Each is powerful in different scenarios.

---

# ------------------------------------------------------------

# ✅ METHOD 1 — Count + Mapping

## Folder: `method-1-count/`

## ⭐ When to Use This Method

* Simple infrastructure
* A few replicated resources
* Quick, reliable configuration
* When developers want predictable index-based naming
* When you don’t need lifecycle changes per instance

Great for small-to-medium deployments.

---

## ⭐ Why This Method Works

Terraform evaluates resources *before* creating anything.
During the “plan” phase, Terraform:

1. Reads the input variable `environment`
2. Looks up the environment-specific instance count using a map
3. Passes that number into the resource's `count`

`count` simply creates that number of copies of a resource.

Prod? → count = 2
Dev? → count = 1

Everything is DRY because the logic is centralised.

---

## 📁 Folder Structure

```
method-1-count/
  main.tf
  variables.tf
  outputs.tf (optional)
```

---

## 📌 variables.tf

```hcl
variable "environment" {
  type        = string
  description = "Environment to deploy (dev or prod)"
}

variable "instance_count_map" {
  type = map(number)
  default = {
    dev  = 1
    prod = 2
  }
}
```

### Explanation

* The map acts like a configuration dictionary.
* It prevents using if-else multiple times in code.
* DRY: If tomorrow you add `"qa" = 3`, you change it in one place.

---

## 📌 main.tf

```hcl
locals {
  instance_count = var.instance_count_map[var.environment]
}

resource "aws_instance" "app" {
  count = local.instance_count

  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = {
    Name = "app-${var.environment}-${count.index}"
  }
}
```

### Line-by-line breakdown

**locals block:**
A computed value that Terraform memorises and reuses.
It reads the map and extracts a number based on environment.

**count meta-argument:**
A built-in Terraform feature that replicates a resource *N* times.

**count.index:**
Index of each instance (0, 1, 2...) — auto-generated.

---

## ⭐ Execution Workflow

User runs:

```
terraform apply -var="environment=prod"
```

Terraform:

* Loads var.environment = "prod"
* Checks map → finds value 2
* Creates two resources:

  * app-prod-0
  * app-prod-1

Repeat for dev — only one is created.

---

## ⭐ Pros

* Easy to read
* Great for beginners
* Predictable naming
* Extremely DRY

## ⭐ Cons

* Can't modify *one* instance without affecting the others
* Not ideal when each instance needs unique settings

---

# ------------------------------------------------------------

# ✅ METHOD 2 — `for_each` with dynamically built map

## Folder: `method-2-foreach/`

This method is more **modern**, flexible, and production-oriented.

---

## ⭐ When to Use This Method

* When each instance might later need unique configuration
* When you want stable, predictable resource addressing
* When you want easier deletion of individual instances

For example, `aws_instance.app["app-prod-1"]` is easier to target than `aws_instance.app[1]`.

---

## ⭐ Why This Method Works

Terraform can only loop with `for_each` over a *map* or *set*.
So first we programmatically **build a map** for the correct number of instances:

```
{
  "app-prod-0" = 0
  "app-prod-1" = 1
}
```

Then `for_each` simply loops through that map.

This allows:

* Named resources
* Clean lifecycle operations
* Zero risk of instance reordering (common count issue)

---

## 📁 Folder Structure

```
method-2-foreach/
  main.tf
  variables.tf
```

---

## 📌 variables.tf

```hcl
variable "environment" {
  type        = string
  description = "Environment to deploy"
}
```

---

## 📌 main.tf

```hcl
locals {
  instance_count = var.environment == "prod" ? 2 : 1

  instances = {
    for num in range(local.instance_count) :
    "app-${var.environment}-${num}" => num
  }
}

resource "aws_instance" "app" {
  for_each = local.instances

  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = {
    Name = each.key
  }
}
```

---

## ⭐ Explanation in depth

### `instance_count` local

A simple conditional. Later you could replace it with a map for more environments.

### `range()`

Generates a list:

* range(1) → [0]
* range(2) → [0, 1]

### The for-expression

```hcl
for num in range(...) :
  "app-prod-0" => 0
```

This builds a map containing keys with meaningful names.

### `for_each`

Loops through the map and creates one EC2 per key.

### `each.key`

Accesses the key ("app-dev-0").

---

## ⭐ Pros

* Best long-term extensibility
* Predictable stable addressing
* Easier lifecycle operations
* Future-proof for scaling

## ⭐ Cons

* Slightly more advanced syntax

---

# ------------------------------------------------------------

# ✅ METHOD 3 — Modules + Variable Inputs

## Folder: `method-3-modules/`

This is the **enterprise-level**, production architecture pattern.
It allows scaling to 50+ environments effortlessly.

---

## ⭐ When to Use

* When multiple team members share Terraform
* When you want infrastructure broken into reusable blocks
* When you want to standardise deployments
* When you want separation of concerns

---

## ⭐ Why This Method Works

We split responsibilities:

### Root module

* Decides *how many* instances
* Holds all logic (dev vs prod)

### Child module

* Only focuses on *how to create* one resource repeated N times

This separation is professional and DRY.

---

## 📁 Folder Structure

```
method-3-modules/
  main.tf
  variables.tf
  modules/
    app/
      main.tf
      variables.tf
```

---

## 📌 modules/app/variables.tf

```hcl
variable "instance_count" {
  type = number
}
```

---

## 📌 modules/app/main.tf

```hcl
resource "aws_instance" "app" {
  count = var.instance_count

  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = {
    Name = "app-instance-${count.index}"
  }
}
```

---

## 📌 root variables.tf

```hcl
variable "environment" {
  type = string
}
```

---

## 📌 root main.tf

```hcl
locals {
  instance_count = var.environment == "prod" ? 2 : 1
}

module "app" {
  source         = "./modules/app"
  instance_count = local.instance_count
}
```

---

## ⭐ Execution Flow

1. User passes environment
2. Root logic computes instance count
3. Module receives instance_count
4. Module creates N EC2 instances
5. All logic, naming, and rules are centralised and DRY

---

## ⭐ Pros

* Best for real companies
* Modules = reusable building blocks
* Great separation of logic
* Teams can version modules
* Easy scale to dozens of environments

## ⭐ Cons

* Slightly more files
* Overkill for very small setups

---

# ------------------------------------------------------------

# 🚀 How to Run (All Methods)

---

```
terraform init
terraform apply -var="environment=dev"
```

or

```
terraform apply -var="environment=prod"
```

---

# ------------------------------------------------------------

# 🎯 Final Recommendations

---

If you want the **industry standard**, go with:

👉 **Method 2** for flexibility
👉 **Method 3** if your org uses modules

Method 1 is perfect for simpler workloads.