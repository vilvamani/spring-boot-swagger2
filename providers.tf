terraform {

  required_version = ">= 0.12"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    random = {
      version = "~> 2.1"
    }

    local = {
      version = "~> 1.2"
    }

    null = {
      version = "~> 2.1"
    }

    template = {
      version = "~> 2.1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
