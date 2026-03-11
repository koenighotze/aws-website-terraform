terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {
    prefix = "terraform/aws-website-terraform/state"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # profile = "koenighotze"
  region = "eu-central-1"
}
