# Requisitos de versión de Terraform y providers (PC-IAC-006, PC-IAC-005)
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.31.0"
      configuration_aliases = [aws.project]
    }
  }
}
