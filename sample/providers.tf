# Configuración de providers para el ejemplo
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.31.0"
    }
  }
}

provider "aws" {
  alias  = "principal"
  region = var.region

  default_tags {
    tags = var.common_tags
  }
}
