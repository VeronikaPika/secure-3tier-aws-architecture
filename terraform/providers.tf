terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
resource "aws_vpc" "failure_test" {
  cidr_block = "10.0.0.0/                                                  16"
  tags = {
    Name = "this-is-misaligned"
  }
}

