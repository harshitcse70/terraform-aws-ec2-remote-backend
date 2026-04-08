# Terraform AWS Infrastructure with Remote Backend (S3 + DynamoDB)

<div align="center">
**A production-ready Terraform project demonstrating AWS infrastructure provisioning with remote state management**


</div>

---

##  Overview

This project demonstrates a **professional-grade Terraform workflow** for provisioning AWS infrastructure with proper remote state management.

### What Makes This Special?

- **Two-Stage Bootstrap Approach**  
- **Secure Remote State Management**    
- **Modular & Scalable Design**  
- **Production-Ready Configuration**
---

##  Key Features

| Feature | Description |
|---------|-------------|
|  **Remote Backend** | Centralized state storage in S3 with versioning |
|  **State Locking** | DynamoDB-based locking prevents concurrent modifications |
|  **Bootstrap Pattern** | Separate infrastructure for backend components |
|  **Modular Structure** | Clean separation of concerns for maintainability |
|  **Idempotent Operations** | Safe to run multiple times without side effects |
|  **Multi-Environment Ready** | Easy to extend for dev/staging/prod environments |
|  **Output Variables** | Structured outputs for integration with other tools |
|  **Security Groups** | Configurable firewall rules for EC2 instances |

---


---

##  Project Structure

```
terraform-aws-remote-backend/
│
├── terraform-bootstrap/          # Stage 1: Backend Infrastructure
│   ├── main.tf                      # S3 bucket + DynamoDB table
│  
│   
│
├── terraform-ec2/                # Stage 2: Application Infrastructure
│   ├── main.tf                      # EC2 instance + Security group
│   ├── backend.tf                   # Remote backend configuration
│   ├── variables.tf                 # Input variables
│   ├── outputs.tf                   # EC2 instance outputs
│  
│   
├── .gitignore                       # Git ignore patterns
├── README.md                        # This file
```

### File Descriptions

| File | Purpose |
|------|---------|
| `main.tf` | Primary resource definitions |
| `backend.tf` | Remote state configuration |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Output value definitions |

---
---

## 🔄 Project Workflow

```
1. Clone Repository
   ↓
2. Configure AWS Credentials
   ↓
3. Stage 1: Bootstrap Backend
   • Deploy S3 bucket
   • Deploy DynamoDB table
   • Note bucket name
   ↓
4. Stage 2: Configure Backend
   • Update backend.tf with bucket name
   • Set variables
   ↓
5. Stage 2: Deploy Infrastructure
   • Deploy EC2 instance
   • Create Security Group
   ↓
6. Verify & Test
   ↓
7. Cleanup (when done)
```


##  Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Cloud Environment                    │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Stage 1: Bootstrap (One-time Setup)                   │ │
│  │  terraform-bootstrap/                                  │ │
│  │                                                        │ │
│  │    ┌──────────────┐        ┌──────────────┐            │ │
│  │    │  S3 Bucket   │        │  DynamoDB    │            │ │
│  │    │  • Versioning│◄──────►│  • LockID    │            │ │
│  │    │  • Encryption│        │  • TTL       │            │ │
│  │    └──────────────┘        └──────────────┘            │ │
│  │          │                        │                    │ │
│  └──────────┼────────────────────────┼────────────────────┘ │
│             │   Stores State         │   Manages Locks      │
│             ▼                        ▼                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Stage 2: Application Infrastructure                   │ │
│  │   terraform-ec2/                                       │ │
│  │                                                        │ │
│  │    ┌──────────────┐        ┌──────────────┐            │ │
│  │    │ Security     │        │ EC2 Instance │            │ │
│  │    │ Group        │───────►│ Ubuntu       │            │ │
│  │    │ • SSH (22)   │        │ t2.micro     │            │ │
│  │    │ • HTTP (80)  │        │              │            │ │
│  │    └──────────────┘        └──────────────┘            │ │
│  │                                   │                    │ │
│  │                             Public IP                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
           ▲
           │
           │  Terraform Apply
           │
    ┌──────┴───────┐
    │  Developer   │
    │  Workstation │
    └──────────────┘
```

### Workflow Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Bootstrap  │────►│   Configure  │────►│   Deploy    │
│  (Stage 1)  │     │   Backend    │     │  (Stage 2)  │
└─────────────┘     └──────────────┘     └─────────────┘
     │                     │                     │
     │                     │                     │
     ▼                     ▼                     ▼
creates S3+DynamoDB    backend.tf          EC2 + Security
  (Local State)      (Remote State)        (Remote State)
```
## Prerequisites

### Required Tools

Ensure you have the following installed:

```bash
# Terraform (version 1.5 or higher)
terraform --version

# AWS CLI (configured with credentials)
aws --version
aws configure list

# Git
git --version
```

### AWS Account Requirements

-  Active AWS account
-  IAM user with programmatic access
-  Required IAM permissions:
  - `s3:*` (for S3 bucket operations)
  - `dynamodb:*` (for DynamoDB table operations)
  - `ec2:*` (for EC2 instance provisioning)
  - `vpc:*` (for security group operations)

### AWS Credentials Setup

```bash
# Option 1: AWS CLI Configuration
aws configure
# Enter: Access Key ID, Secret Access Key, Region (e.g., us-east-1), Output format (json)

# Option 2: Environment Variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 3: AWS Profiles
aws configure --profile terraform-user
export AWS_PROFILE=terraform-user
```
## Detailed Setup

### Stage 1: Bootstrap Infrastructure

This stage creates the foundational components needed for remote state management.

#### 1.1 Navigate to Bootstrap Directory

```bash
cd terraform-bootstrap
```
#### 1.2 Initialize Terraform

```bash
terraform init
```

**Expected Output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v5.31.0...

Terraform has been successfully initialized!
```

#### 1.3 Plan Infrastructure

```bash
terraform plan
```

**Review the plan carefully. You should see:**
-  1 S3 bucket to be created
-  1 DynamoDB table to be created

#### 1.4 Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted.

**Expected Output:**
```
aws_s3_bucket.terraform_state: Creating...
aws_dynamodb_table.terraform_lock: Creating...
aws_s3_bucket.terraform_state: Creation complete after 2s
aws_dynamodb_table.terraform_lock: Creation complete after 8s

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
s3_bucket_name = "my-terraform-state-bucket-12345"
dynamodb_table_name = "terraform-lock-table"
```

#### 1.5 Verify Resources

```bash
# Verify S3 bucket
aws s3 ls | grep terraform-state

# Verify DynamoDB table
aws dynamodb describe-table --table-name terraform-lock-table
```

---

### Stage 2: Application Infrastructure/Configure Remote Backend

This stage deploys your EC2 instance using the remote backend.

#### 2.1 Navigate to EC2 Directory

```bash
cd ../terraform-ec2
```

#### 2.2 Configure remote Backend

Edit `backend.tf` with your S3 bucket name:

#### 2.3 Initialize with Remote Backend

```bash
terraform init   # connects to S3 backend
```

#### 2.4 Plan Infrastructure

```bash
terraform plan 
```

**Review the plan. You should see:**
-  1 EC2 instance to be created
-  1 Security group to be created

#### 2.5 Apply Configuration

```bash
terraform apply 
```


#### 2.6 Verify Deployment

```bash
# Get outputs
terraform output

# SSH to instance
ssh -i ~/.ssh/my-ec2-keypair.pem ubuntu@$(terraform output -raw instance_public_ip)

# Check state in S3
aws s3 ls s3://my-terraform-state-bucket-12345/ec2/
```

## 🗄️ State Management

### Understanding Terraform State

Terraform state is a JSON file that maps your configuration to real infrastructure.

**Key Points:**
- **Tracks Resources**: Maintains inventory of managed infrastructure
-  **Plans Changes**: Compares desired vs. actual state
-  **Resource Relationships**: Manages dependencies between resources
-  **Sensitive Data**: Can contain passwords, keys (must be secured)

### Remote State Benefits

| Feature | Local State | Remote State |
|---------|-------------|--------------|
| Team Collaboration | no | yes|
| State Locking | no | yes |
| Versioning | no | yes |
| Encryption | no | yes|
| Backup | Manual | Automatic |
| Concurrent Access Control | no | yes |

### State Locking

When you run `terraform apply`, Terraform:
1. Acquires lock in DynamoDB
2. Reads current state from S3
3. Plans and applies changes
4. Writes new state to S3
5. Releases lock

**Lock Entry Example (DynamoDB):**
```json
{
  "LockID": "my-bucket/ec2/terraform.tfstate",
  "Info": "{\"ID\":\"abc123\",\"Operation\":\"OperationTypeApply\",\"Who\":\"user@host\",\"Version\":\"1.5.0\",\"Created\":\"2024-01-15T10:30:00Z\"}",
  "Digest": "..."
}
```

### State Commands

```bash
# View current state
terraform state list

# Show specific resource
terraform state show aws_instance.web_server

# Remove resource from state (doesn't delete from AWS)
terraform state rm aws_instance.web_server

# Move resource in state
terraform state mv aws_instance.web_server aws_instance.web_server_new

# Pull remote state
terraform state pull > backup.tfstate

# Import existing AWS resource
terraform import aws_instance.web_server i-0123456789abcdef0
```
### How State Locking Works

```
User A                     DynamoDB                    User B
  │                           │                           │
  │─── apply ───────────────► │                           │
  │                       [Lock]                          │
  │                           │ ◄──── apply ──────────────│
  │                           │                       [Blocked]
  │                           │                       [Waiting]
  │◄─── Complete ─────────────│                           │
  │                      [Unlock]                         │
  │                           │ ──── Lock ───────────────►│
  │                           │                    [Proceeds]
```

## 🧹 Cleanup

```bash
# Destroy in reverse order

# 1. Destroy EC2 infrastructure
cd terraform-ec2
terraform destroy

# 2. Destroy bootstrap (only after EC2 is destroyed)
cd ../terraform-bootstrap
terraform destroy
```

