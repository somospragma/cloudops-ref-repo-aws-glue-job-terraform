# Data sources del ejemplo (PC-IAC-026)

data "aws_iam_role" "glue" {
  provider = aws.principal
  name     = var.glue_role_name
}

data "aws_kms_alias" "glue" {
  provider = aws.principal
  name     = var.kms_alias_name
}

data "aws_s3_bucket" "raw" {
  provider = aws.principal
  bucket   = var.raw_bucket_name
}

data "aws_s3_bucket" "scripts" {
  provider = aws.principal
  bucket   = var.scripts_bucket_name
}
