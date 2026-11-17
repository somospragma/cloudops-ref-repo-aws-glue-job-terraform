# Valores de variables para el ejemplo (sin IDs ni secretos hardcodeados)
client      = "pragma"
project     = "sopp"
environment = "dev"

common_tags = {
  Client      = "pragma"
  Project     = "sopp"
  Environment = "dev"
  Owner       = "cloudops"
  CostCenter  = "sopp"
}

glue_role_name      = "pragma-sopp-dev-iam-glue"
kms_alias_name      = "alias/pragma-sopp-dev-kms-glue"
raw_bucket_name     = "pragma-sopp-dev-s3-raw"
scripts_bucket_name = "pragma-sopp-dev-s3-scripts"

glue_databases = {
  raw = {
    description = "Catálogo de datos raw de costos y tags por cuenta"
  }
}

glue_security_configurations = {
  raw = {
    kms_key_arn = "" # Se inyecta desde data.aws_kms_alias
  }
}

glue_crawlers = {
  costos = {
    role_arn                   = "" # Se inyecta desde data.aws_iam_role
    database_key               = "raw"
    security_configuration_key = "raw"
    table_prefix               = "raw_"
    s3_targets                 = [{ path = "" }] # Se inyecta el bucket raw
  }
}

glue_jobs = {
  costos = {
    role_arn                   = ""
    script_location            = ""
    security_configuration_key = "raw"
    default_arguments = {
      "--job-language"                     = "python"
      "--enable-continuous-cloudwatch-log" = "true"
    }
  }
}

glue_workflows = {
  costos = {
    description = "Procesa datos de costos cuando llegan a S3"
  }
}

glue_triggers = {
  start = {
    type         = "EVENT"
    workflow_key = "costos"
    event_batching_condition = {
      batch_size   = 1
      batch_window = 60
    }
    actions = [{ crawler_key = "costos" }]
  }
  transform = {
    type         = "CONDITIONAL"
    workflow_key = "costos"
    predicate = {
      conditions = [{ crawler_key = "costos", crawl_state = "SUCCEEDED" }]
    }
    actions = [{ job_key = "costos" }]
  }
}
