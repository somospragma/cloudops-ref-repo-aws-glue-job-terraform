# Recursos principales del módulo Glue
# PC-IAC-023: solo recursos intrínsecos a Glue. Roles IAM, KMS y buckets se reciben por variables.

############################################################################
# Data Catalog
############################################################################
resource "aws_glue_catalog_database" "this" {
  provider = aws.project
  for_each = var.glue_databases

  name         = local.database_names[each.key]
  description  = each.value.description
  location_uri = each.value.location_uri

  tags = merge(
    { Name = local.database_names[each.key] },
    each.value.additional_tags
  )
}

############################################################################
# Security configuration (cifrado en reposo con CMK, PC-IAC-020)
############################################################################
resource "aws_glue_security_configuration" "this" {
  provider = aws.project
  for_each = var.glue_security_configurations

  name = local.security_configuration_names[each.key]

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = each.value.cloudwatch_encryption_mode
      kms_key_arn                = each.value.cloudwatch_encryption_mode == "DISABLED" ? null : each.value.kms_key_arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = each.value.job_bookmarks_encryption_mode
      kms_key_arn                   = each.value.job_bookmarks_encryption_mode == "DISABLED" ? null : each.value.kms_key_arn
    }

    s3_encryption {
      s3_encryption_mode = each.value.s3_encryption_mode
      kms_key_arn        = each.value.s3_encryption_mode == "SSE-KMS" ? each.value.kms_key_arn : null
    }
  }
}

############################################################################
# Crawlers
############################################################################
resource "aws_glue_crawler" "this" {
  provider = aws.project
  for_each = local.crawlers_resolved

  name                   = local.crawler_names[each.key]
  description            = each.value.description
  role                   = each.value.role_arn
  database_name          = each.value.resolved_database_name
  schedule               = each.value.schedule
  table_prefix           = each.value.table_prefix
  security_configuration = each.value.resolved_security_configuration

  dynamic "s3_target" {
    for_each = each.value.s3_targets
    content {
      path       = s3_target.value.path
      exclusions = s3_target.value.exclusions
    }
  }

  recrawl_policy {
    recrawl_behavior = each.value.recrawl_behavior
  }

  schema_change_policy {
    delete_behavior = each.value.schema_change_delete
    update_behavior = each.value.schema_change_update
  }

  tags = merge(
    { Name = local.crawler_names[each.key] },
    each.value.additional_tags
  )

  depends_on = [aws_glue_catalog_database.this, aws_glue_security_configuration.this]
}

############################################################################
# Jobs
############################################################################
resource "aws_glue_job" "this" {
  provider = aws.project
  for_each = local.jobs_resolved

  name                   = local.job_names[each.key]
  description            = each.value.description
  role_arn               = each.value.role_arn
  glue_version           = each.value.glue_version
  worker_type            = each.value.command_name == "pythonshell" ? null : each.value.worker_type
  number_of_workers      = each.value.command_name == "pythonshell" ? null : each.value.number_of_workers
  timeout                = each.value.timeout_minutes
  max_retries            = each.value.max_retries
  execution_class        = each.value.execution_class
  connections            = each.value.connections
  default_arguments      = each.value.default_arguments
  security_configuration = each.value.resolved_security_configuration

  command {
    name            = each.value.command_name
    script_location = each.value.script_location
    python_version  = each.value.python_version
  }

  execution_property {
    max_concurrent_runs = each.value.max_concurrent_runs
  }

  tags = merge(
    { Name = local.job_names[each.key] },
    each.value.additional_tags
  )

  depends_on = [aws_glue_security_configuration.this]
}

############################################################################
# Workflows
############################################################################
resource "aws_glue_workflow" "this" {
  provider = aws.project
  for_each = var.glue_workflows

  name                   = local.workflow_names[each.key]
  description            = each.value.description
  default_run_properties = each.value.default_run_properties
  max_concurrent_runs    = each.value.max_concurrent_runs

  tags = merge(
    { Name = local.workflow_names[each.key] },
    each.value.additional_tags
  )
}

############################################################################
# Triggers
############################################################################
resource "aws_glue_trigger" "this" {
  provider = aws.project
  for_each = local.triggers_resolved

  name              = local.trigger_names[each.key]
  description       = each.value.description
  type              = each.value.type
  workflow_name     = each.value.resolved_workflow_name
  schedule          = each.value.type == "SCHEDULED" ? each.value.schedule : null
  enabled           = each.value.type == "ON_DEMAND" || each.value.type == "EVENT" ? null : each.value.enabled
  start_on_creation = each.value.start_on_creation

  dynamic "actions" {
    for_each = each.value.resolved_actions
    content {
      job_name     = actions.value.job_name
      crawler_name = actions.value.crawler_name
      arguments    = length(actions.value.arguments) > 0 ? actions.value.arguments : null
    }
  }

  dynamic "predicate" {
    for_each = each.value.predicate != null ? [each.value.predicate] : []
    content {
      logical = predicate.value.logical

      dynamic "conditions" {
        for_each = each.value.resolved_conditions
        content {
          job_name         = conditions.value.job_name
          crawler_name     = conditions.value.crawler_name
          state            = conditions.value.job_name != null ? conditions.value.state : null
          crawl_state      = conditions.value.crawler_name != null ? coalesce(conditions.value.crawl_state, "SUCCEEDED") : null
          logical_operator = conditions.value.logical_operator
        }
      }
    }
  }

  dynamic "event_batching_condition" {
    for_each = each.value.event_batching_condition != null ? [each.value.event_batching_condition] : []
    content {
      batch_size   = event_batching_condition.value.batch_size
      batch_window = event_batching_condition.value.batch_window
    }
  }

  tags = merge(
    { Name = local.trigger_names[each.key] },
    each.value.additional_tags
  )

  depends_on = [aws_glue_job.this, aws_glue_crawler.this, aws_glue_workflow.this]
}
