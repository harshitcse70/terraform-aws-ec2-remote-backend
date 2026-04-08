# Terraform EC2 Infrastructure - Remote Backend Deployment

<div align="center">

**Stage 2: Deploying EC2 Instance with Security Group using Remote State**

[← Back to Main Project](../README.md) | [← Bootstrap Guide](../terraform-bootstrap/BOOTSTRAP_README.md)

</div>

---

## Overview

This stage deploys your **application infrastructure** on AWS using the **remote backend** created in the bootstrap stage. It provisions:
- **EC2 instance** (Ubuntu server)
- **Security Group** (firewall rules)

### Key Difference from Bootstrap

| Aspect | Bootstrap Stage | EC2 Stage |
|--------|----------------|-----------|
| State Storage | Local (terraform.tfstate) | Remote (S3 bucket) |
| State Locking | Not applicable | DynamoDB |
| Collaboration | Single user | Team-ready |
| Versioning | Manual | Automatic (S3) |

---

##  What Gets Created

### 1. EC2 Instance

```hcl
Resource: aws_instance
Purpose:  Virtual server for applications
Specifications:
  • Instance Type: t2.micro (1 vCPU, 1 GB RAM)
  • OS: Ubuntu 22.04 LTS
  • Storage: 8 GB EBS volume
  • Network: Public IP enabled
  • Cost: ~$8.50/month (Free Tier: $0 for 750 hrs/month)
```

**Use Cases:**
- Web server (Apache, Nginx)
- Application server (Node.js, Python)
- Development environment
- Testing server

### 2. Security Group

```hcl
Resource: aws_security_group
Purpose:  Virtual firewall for EC2 instance
Default Rules:
  Ingress:
    • SSH (Port 22)    - Your IP only
    • HTTP (Port 80)   - All IPs (0.0.0.0/0)
  Egress:
    • All traffic      - All destinations
```

---

##  Prerequisites

### 1. Bootstrap Must Be Complete

- S3 bucket created  
- DynamoDB table created  
- You have the bucket name from bootstrap outputs

```bash
# Verify bootstrap outputs
cd ../terraform-bootstrap
terraform output s3_bucket_name
# Copy this bucket name - you'll need it!
```

### 2. EC2 Key Pair

You need an SSH key pair to access the EC2 instance.

**Check existing keys:**
```bash
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName'
```

**Create new key pair:**
```bash
# Create key pair
aws ec2 create-key-pair \
  --key-name my-ec2-keypair \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/my-ec2-keypair.pem

# Set correct permissions
chmod 400 ~/.ssh/my-ec2-keypair.pem

# Verify
ls -l ~/.ssh/my-ec2-keypair.pem
# Should show: -r-------- (400 permissions)
```

### 3. Get Your Public IP

For security group configuration:

```bash
# Get your current public IP
curl -s https://checkip.amazonaws.com

# Or
curl -s https://ifconfig.me

# Example output: 203.0.113.42
```

---

##  Backend Configuration

### Step 1: Update backend.tf

Open `backend.tf` and update with your S3 bucket name:

```hcl
terraform {
  backend "s3" {
    bucket         = "YOUR-S3-BUCKET-NAME-HERE"  # ← Update this!
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
```

**Example:**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-12345"  # From bootstrap output
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
```

### Understanding Backend Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `bucket` | Your S3 bucket name | From bootstrap stage |
| `key` | `ec2/terraform.tfstate` | Path within bucket for this state file |
| `region` | `us-east-1` | AWS region (match your resources) |
| `dynamodb_table` | `terraform-lock-table` | From bootstrap stage |
| `encrypt` | `true` | Encrypt state file at rest |

```


---

## Deployment Steps

### Step 1: Navigate to EC2 Directory

```bash
cd terraform-ec2
```

### Step 2: Initialize with Remote Backend

```bash
terraform init
```

**Expected Output:**
```
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v5.31.0

Terraform has been successfully initialized!
```

**What Just Happened?**
-  Connected to S3 backend
-  Verified DynamoDB table exists
-  Downloaded AWS provider
-  Ready to manage infrastructure

### Step 3: Validate Configuration

```bash
terraform validate
```

**Expected Output:**
```
Success! The configuration is valid.
```

### Step 4: Plan Infrastructure

```bash
terraform plan
```

**Review the plan. You should see:**

```
Terraform will perform the following actions:

  # aws_instance.web_server will be created
  + resource "aws_instance" "web_server" {
      + ami                          = "ami-0c55b159cbfafe1f0"
      + instance_type                = "t2.micro"
      + key_name                     = "my-ec2-keypair"
      + public_ip                    = (known after apply)
      + subnet_id                    = (known after apply)
      + tags                         = {
          + "Name" = "web-server-01"
        }
      ...
    }

  # aws_security_group.web_sg will be created
  + resource "aws_security_group" "web_sg" {
      + name                   = "web-server-sg"
      + description            = "Security group for web server"
      + ingress                = [
          + {
              + from_port   = 22
              + to_port     = 22
              + protocol    = "tcp"
              + cidr_blocks = ["203.0.113.42/32"]
            },
          + {
              + from_port   = 80
              + to_port     = 80
              + protocol    = "tcp"
              + cidr_blocks = ["0.0.0.0/0"]
            },
        ]
      ...
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

### Step 5: Save Plan (Optional)

```bash
terraform plan -out=tfplan
```

This saves the plan for later execution, ensuring exactly what you reviewed gets applied.

### Step 6: Apply Configuration

```bash
# If you saved a plan:
terraform apply tfplan

# Or directly:
terraform apply
```

Type `yes` when prompted.

**Expected Output:**
```
aws_security_group.web_sg: Creating...
aws_security_group.web_sg: Creation complete after 3s [id=sg-0123456789abcdef0]
aws_instance.web_server: Creating...
aws_instance.web_server: Still creating... [10s elapsed]
aws_instance.web_server: Still creating... [20s elapsed]
aws_instance.web_server: Creation complete after 32s [id=i-0123456789abcdef0]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-0123456789abcdef0"
instance_public_ip = "54.123.45.67"
instance_state = "running"
security_group_id = "sg-0123456789abcdef0"
```

** Time:** ~30-40 seconds

---



<div align="center">

[← Back to Main Project](../README.md) | [← Bootstrap Guide](../terraform-bootstrap/README.md)

**Stage 2 of 2 Complete** 

** Congratulations! Your EC2 instance is live!**

</div>
