terraform {
  backend "s3" {
    bucket         = "499989195354-terraform-states"
    key            = "ec2/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock"
  }
}
