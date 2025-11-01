# Terraform and AWS Provider Configuration

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
  region = "us-east-2"

  default_tags {
    tags = {
      Project     = "CallData Foundation Platform"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Repository  = "calldata-foundation"
    }
  }
}
