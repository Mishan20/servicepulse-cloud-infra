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

module "servicepulse" {
  source = "../../modules/servicepulse-env"

  environment       = "dev"
  instance_type     = var.instance_type
  root_volume_size  = var.root_volume_size
  ssh_public_key    = var.ssh_public_key
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}
