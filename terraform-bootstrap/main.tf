terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Get AWS account ID
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# -----------------------------
# S3 Bucket (Remote State)
# -----------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.account_id}-terraform-states"

  tags = {
    Name = "Terraform State Bucket"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------
# DynamoDB Table (Locking)
# -----------------------------
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# -----------------------------
# Outputs
# -----------------------------
output "bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.terraform_lock.name
}
