## **1. Why this task exists**

* Automating repo creation saves repetitive work and ensures consistency across projects.
* It helps teams enforce naming conventions (`techXXX-firstname-tf-created-repo`), permissions, and default settings.
* Terraform can manage GitHub resources declaratively, just like it does for cloud infrastructure. This is Infrastructure as Code (IaC), but applied to GitHub.

---

## **2. How Terraform will authenticate with GitHub**

Terraform needs permission to create repos. You can do this via a **Personal Access Token (PAT)**.

Steps:

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token.
2. Give it these scopes (minimum required):

   * `repo` → full control of private and public repositories (for creating repos)
   * `admin:repo_hook` → if you want to add webhooks later
3. Copy the token. Keep it secret.

**In Terraform**:

* Store the token in an environment variable for security:

```bash
export GITHUB_TOKEN="ghp_xxx_your_token_here"

```

* Terraform GitHub provider reads this automatically.

---

## **3. Terraform configuration**

Create a folder for this task. Inside, create a file `main.tf`:

```hcl
# main.tf
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  # Token picked up from GITHUB_TOKEN env variable
  owner = "your-github-username"  # replace with your GitHub username
}

resource "github_repository" "my_repo" {
  name        = "techXXX-sherin-tf-created-repo"  # use your username/techXXX
  description = "Repo created using Terraform"
  visibility  = "public"
  auto_init   = true  # optional, initializes with README
}
```


<br><br><br>


## Test if token can be read by terraform

### **1. Test from the command line (quick check)**

You can use `curl` to see if GitHub accepts your token:

```bash
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

* If the token works, you’ll get a JSON response with your GitHub username, ID, etc.
* If it fails, you’ll get a 401 Unauthorized error → check token or env variable spelling.

---

### **2. Check in Terraform**

Terraform reads the token automatically from `GITHUB_TOKEN`. You can run:

```bash
terraform plan
```

* If the provider authenticates, Terraform will show that it plans to create your repo.
* If it can’t authenticate, you’ll see an error like `Failed to get current user from GitHub: 401 Unauthorized`.

---

### **3. Make sure the environment variable is exported in the same session**

```bash
export GITHUB_TOKEN="ghp_xxx_your_token_here"
echo $GITHUB_TOKEN  # should print your token
```


<br><br><br>

### **1. Why we declare the provider for GitHub**

* Terraform needs to know **which plugin/provider to use** to talk to an API.
* For AWS, Terraform automatically knows the official `aws` provider (it’s very standard, pre-installed in Terraform’s registry), so you can often skip specifying `source` and `version` unless you need a specific version.
* GitHub isn’t built-in; it’s a community/HashiCorp-supported provider. Terraform needs **explicit instructions** where to find it and which version.

So this block:

```hcl
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}
```

…is basically saying:

> “Terraform, if you want to manage GitHub, go fetch the provider plugin at `integrations/github`, version 5.x.”

Without it, Terraform might not know which plugin to download.

---

### **2. Why we didn’t need this for AWS**

* AWS provider is **built-in and extremely common**, so Terraform often auto-resolves it.
* Unless you want to pin a specific version or source, the minimal provider block works fine:

```hcl
provider "aws" {
  region = "eu-west-1"
}
```

* Terraform auto-downloads the official `aws` provider from the registry, no `required_providers` block strictly needed.

---

### **3. Another way to do this for GitHub**

Yes, you could simplify slightly if you’re okay with the latest version:

```hcl
provider "github" {
  owner = "your-username"
  token = var.github_token  # token from variable
}
```

And in `variables.tf`:

```hcl
variable "github_token" {
  type      = string
  default   = ""  # or read from env
  sensitive = true
}
```

Terraform will still download the latest provider automatically, but you **lose version control**, which is why the `required_providers` block is recommended for reproducibility.