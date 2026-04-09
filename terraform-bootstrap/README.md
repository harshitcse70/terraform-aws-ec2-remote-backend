#  Terraform Bootstrap - Remote Backend Setup

<div align="center">

**Stage 1: Creating S3 Bucket and DynamoDB Table for Remote State Management**

[← Back to Main Project](../README.md)

</div>

---


##  Overview

This bootstrap stage creates the **foundational infrastructure** required for Terraform remote state management. It provisions:
- **S3 bucket** for storing Terraform state files
- **DynamoDB table** for state locking mechanism

### Why Bootstrap?

The bootstrap approach solves the **chicken-and-egg problem**:
- You need S3 and DynamoDB to use remote state
- But you need Terraform to create S3 and DynamoDB
- Solution: Create backend resources first using **local state**, then use them for all future infrastructure

### State Management

>  **Important:** This bootstrap infrastructure uses **local state** (stored in this directory as `terraform.tfstate`). All subsequent infrastructure (EC2, etc.) will use **remote state** (stored in the S3 bucket created here).

---

##  What Gets Created

### 1. S3 Bucket

```hcl
Resource: aws_s3_bucket
Purpose:  Stores Terraform state files
Features:
   Versioning enabled (rollback capability)
   Encryption enabled (AES-256 or KMS)
   Public access blocked
   Lifecycle policies (optional)
```

**Example Bucket Configuration:**
- Name: `my-terraform-state-bucket-12345`
- Region: `us-east-1`
- Storage Class: Standard
- Estimated Cost: ~$0.02/month for < 1GB

### 2. DynamoDB Table

```hcl
Resource: aws_dynamodb_table
Purpose:  Manages state locking
Schema:
  - LockID (String, Hash Key)
Billing:  On-demand mode
```

**Example Table Configuration:**
- Name: `terraform-lock-table`
- Billing Mode: Pay-per-request
- Estimated Cost: ~$0.01/month

---

##  Prerequisites

### Required

-  Terraform v1.5 or higher
-  AWS CLI configured with credentials
-  IAM permissions for S3 and DynamoDB
-  Check AWS region
   ```bash
   aws configure get region # Should return your target region (e.g., us-east-1)
   ```
```
```

##  Deployment Steps

### Step 1: Initialize Terraform

```bash
cd terraform-bootstrap
terraform init
```
### Step 2: Validate Configuration

```bash
terraform validate
```

**Expected Output:**
```
Success! The configuration is valid.
```

### Step 3: Plan Infrastructure

```bash
terraform plan
```

**Review the plan carefully. You should see:**

```
Terraform will perform the following actions:

  # aws_dynamodb_table.terraform_lock will be created
  + resource "aws_dynamodb_table" "terraform_lock" {
      + name           = "terraform-lock-table"
      + billing_mode   = "PAY_PER_REQUEST"
      + hash_key       = "LockID"
      ...
    }

  # aws_s3_bucket.terraform_state will be created
  + resource "aws_s3_bucket" "terraform_state" {
      + bucket        = "my-terraform-state-bucket-12345"
      + force_destroy = false
      ...
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

### Step 4: Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted.

**Expected Output:**
```
aws_s3_bucket.terraform_state: Creating...
aws_dynamodb_table.terraform_lock: Creating...
aws_s3_bucket.terraform_state: Creation complete after 2s [id=my-terraform-state-bucket-12345]
aws_dynamodb_table.terraform_lock: Creation complete after 8s [id=terraform-lock-table]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

dynamodb_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-lock-table"
dynamodb_table_name = "terraform-lock-table"
s3_bucket_arn = "arn:aws:s3:::my-terraform-state-bucket-12345"
s3_bucket_name = "my-terraform-state-bucket-12345"
```

** Time:** ~10-15 seconds

---

##  Verification

### 1. Verify S3 Bucket

```bash
# List buckets
aws s3 ls | grep terraform-state

# Expected output:
# 2024-01-15 10:30:00 my-terraform-state-bucket-12345

# Check bucket versioning
aws s3api get-bucket-versioning --bucket my-terraform-state-bucket-12345

# Expected output:
# {
#     "Status": "Enabled"
# }

# Check bucket encryption
aws s3api get-bucket-encryption --bucket my-terraform-state-bucket-12345

# Expected output:
# {
#     "ServerSideEncryptionConfiguration": {
#         "Rules": [
#             {
#                 "ApplyServerSideEncryptionByDefault": {
#                     "SSEAlgorithm": "AES256"
#                 }
#             }
#         ]
#     }
# }
```

### 2. Verify DynamoDB Table

```bash
# Describe table
aws dynamodb describe-table --table-name terraform-lock-table

# Expected output (abbreviated):
# {
#     "Table": {
#         "TableName": "terraform-lock-table",
#         "TableStatus": "ACTIVE",
#         "BillingModeSummary": {
#             "BillingMode": "PAY_PER_REQUEST"
#         },
#         "KeySchema": [
#             {
#                 "AttributeName": "LockID",
#                 "KeyType": "HASH"
#             }
#         ]
#     }
# }
```
---

##  Outputs

After successful deployment, note these outputs:

```bash
terraform output
```

### Output Values

| Output | Description | Usage |
|--------|-------------|-------|
| `s3_bucket_name` | S3 bucket name | Use in backend.tf for EC2 stage |
| `s3_bucket_arn` | S3 bucket ARN | For IAM policies |
| `dynamodb_table_name` | DynamoDB table name | Use in backend.tf |
| `dynamodb_table_arn` | DynamoDB table ARN | For IAM policies |

### Save Outputs

##  Cleanup

>  **Warning:** Only destroy bootstrap infrastructure after destroying ALL other infrastructure that uses it!

```bash
# 1. Verify no resources depend on this backend
aws s3 ls s3://my-terraform-state-bucket-12345/

# 2. If empty (or only contains bootstrap state), destroy
terraform destroy

# 3. Confirm
# Type: yes
```

**Expected Output:**
```
aws_s3_bucket.terraform_state: Destroying... [id=my-terraform-state-bucket-12345]
aws_dynamodb_table.terraform_lock: Destroying... [id=terraform-lock-table]
aws_s3_bucket.terraform_state: Destruction complete after 2s
aws_dynamodb_table.terraform_lock: Destruction complete after 3s

Destroy complete! Resources: 2 destroyed.
```


<div align="center">

[← Back to Main Project](../README.md) | [Continue to EC2 Setup →](../terraform-ec2/EC2_README.md)

**Stage 1 of 2 Complete** 

</div>

