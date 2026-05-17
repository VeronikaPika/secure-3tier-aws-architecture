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

# Test Block to break the CI/CD layout engine
resource     "aws_vpc"     "test_breaking_the_pipeline" {
  cidr_block = "10.0.0.0/16"
     tags = {
  Name = "broken-vpc-alignment-test"
    }
}
