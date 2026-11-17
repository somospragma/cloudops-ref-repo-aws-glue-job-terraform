# Valores locales y transformaciones (PC-IAC-003, PC-IAC-009, PC-IAC-012)
locals {
  # 1. Prefijo base de gobernanza
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  # 2. Nombres físicos: {client}-{project}-{environment}-{type}-{key}
  # Los nombres de database en Glue/Athena usan guion bajo en lugar de guion.
  database_names = {
    for key, config in var.glue_databases : key => replace("${local.governance_prefix}-glue-db-${key}", "-", "_")
  }

  security_configuration_names = {
    for key, config in var.glue_security_configurations : key => "${local.governance_prefix}-glue-sec-${key}"
  }

  crawler_names = {
    for key, config in var.glue_crawlers : key => "${local.governance_prefix}-glue-crawler-${key}"
  }

  job_names = {
    for key, config in var.glue_jobs : key => "${local.governance_prefix}-glue-job-${key}"
  }

  workflow_names = {
    for key, config in var.glue_workflows : key => "${local.governance_prefix}-glue-wf-${key}"
  }

  trigger_names = {
    for key, config in var.glue_triggers : key => "${local.governance_prefix}-glue-trg-${key}"
  }

  # 3. Estructuras transformadas: resuelven referencias por clave a nombres físicos
  crawlers_resolved = {
    for key, config in var.glue_crawlers : key => merge(config, {
      resolved_database_name = config.database_key != null ? local.database_names[config.database_key] : config.database_name
      resolved_security_configuration = (
        config.security_configuration_key != null ? local.security_configuration_names[config.security_configuration_key] : null
      )
    })
  }

  jobs_resolved = {
    for key, config in var.glue_jobs : key => merge(config, {
      resolved_security_configuration = (
        config.security_configuration_key != null ? local.security_configuration_names[config.security_configuration_key] : null
      )
    })
  }

  triggers_resolved = {
    for key, config in var.glue_triggers : key => merge(config, {
      resolved_workflow_name = config.workflow_key != null ? local.workflow_names[config.workflow_key] : null
      resolved_actions = [
        for action in config.actions : {
          job_name     = action.job_key != null ? local.job_names[action.job_key] : null
          crawler_name = action.crawler_key != null ? local.crawler_names[action.crawler_key] : null
          arguments    = action.arguments
        }
      ]
      resolved_conditions = config.predicate != null ? [
        for condition in config.predicate.conditions : {
          job_name         = condition.job_key != null ? local.job_names[condition.job_key] : null
          crawler_name     = condition.crawler_key != null ? local.crawler_names[condition.crawler_key] : null
          state            = condition.state
          crawl_state      = condition.crawl_state
          logical_operator = condition.logical_operator
        }
      ] : []
    })
  }
}
