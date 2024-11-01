# ./provider.tf

# provider
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

# version
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0"
    }
  }
}
