variable "aws_region" {
  default = "eu-north-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "EC2 Key Pair"
}
