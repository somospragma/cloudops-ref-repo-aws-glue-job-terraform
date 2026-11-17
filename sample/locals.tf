# Transformaciones del ejemplo: inyección dinámica de IDs desde data sources (PC-IAC-009, PC-IAC-026)
locals {
  glue_databases_transformed = {
    for key, config in var.glue_databases : key => merge(config, {
      location_uri = length(coalesce(config.location_uri, "")) > 0 ? config.location_uri : "s3://${data.aws_s3_bucket.raw.id}/"
    })
  }

  glue_security_configurations_transformed = {
    for key, config in var.glue_security_configurations : key => merge(config, {
      kms_key_arn = length(config.kms_key_arn) > 0 ? config.kms_key_arn : data.aws_kms_alias.glue.target_key_arn
    })
  }

  glue_crawlers_transformed = {
    for key, config in var.glue_crawlers : key => merge(config, {
      role_arn = length(config.role_arn) > 0 ? config.role_arn : data.aws_iam_role.glue.arn
      s3_targets = [
        for target in config.s3_targets : merge(target, {
          path = length(target.path) > 0 ? target.path : "s3://${data.aws_s3_bucket.raw.id}/"
        })
      ]
    })
  }

  glue_jobs_transformed = {
    for key, config in var.glue_jobs : key => merge(config, {
      role_arn        = length(config.role_arn) > 0 ? config.role_arn : data.aws_iam_role.glue.arn
      script_location = length(config.script_location) > 0 ? config.script_location : "s3://${data.aws_s3_bucket.scripts.id}/glue/${key}.py"
    })
  }
}
