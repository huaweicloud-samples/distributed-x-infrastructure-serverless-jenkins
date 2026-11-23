terraform {
  required_version = ">= 1.5"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.70"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
  backend "local" {}
}

provider "huaweicloud" {
  region      = var.region
  domain_name = "GT-dgcmy"
}

locals {
  name_prefix = var.name_prefix
  common_tags = {
    project = local.name_prefix
    managed = "terraform"
  }
}
