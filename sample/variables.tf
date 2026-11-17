# Variables del ejemplo
variable "region" {
  description = "Región AWS de despliegue."
  type        = string
  default     = "us-east-1"
}

variable "client" {
  description = "Nombre del cliente."
  type        = string
}

variable "project" {
  description = "Nombre del proyecto."
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue."
  type        = string
}

variable "common_tags" {
  description = "Tags transversales (Client, Project, Environment, Owner, CostCenter)."
  type        = map(string)
}

variable "glue_role_name" {
  description = "Nombre del rol IAM de Glue creado en el dominio Security."
  type        = string
}

variable "kms_alias_name" {
  description = "Alias de la CMK (alias/...) creada en el dominio Security."
  type        = string
}

variable "raw_bucket_name" {
  description = "Nombre del bucket S3 raw."
  type        = string
}

variable "scripts_bucket_name" {
  description = "Nombre del bucket S3 con los scripts de Glue."
  type        = string
}

variable "glue_databases" {
  description = "Configuración de databases (ver variables del módulo)."
  type = map(object({
    description     = optional(string, "")
    location_uri    = optional(string, null)
    additional_tags = optional(map(string), {})
  }))
  default = {}
}

variable "glue_security_configurations" {
  description = "Configuración de security configurations."
  type = map(object({
    kms_key_arn                   = string
    cloudwatch_encryption_mode    = optional(string, "SSE-KMS")
    job_bookmarks_encryption_mode = optional(string, "CSE-KMS")
    s3_encryption_mode            = optional(string, "SSE-KMS")
  }))
  default = {}
}

variable "glue_crawlers" {
  description = "Configuración de crawlers."
  type = map(object({
    role_arn                   = string
    database_key               = optional(string, null)
    database_name              = optional(string, "")
    description                = optional(string, "")
    schedule                   = optional(string, null)
    table_prefix               = optional(string, null)
    security_configuration_key = optional(string, null)
    recrawl_behavior           = optional(string, "CRAWL_EVERYTHING")
    schema_change_delete       = optional(string, "LOG")
    schema_change_update       = optional(string, "UPDATE_IN_DATABASE")
    s3_targets = list(object({
      path       = string
      exclusions = optional(list(string), [])
    }))
    additional_tags = optional(map(string), {})
  }))
  default = {}
}

variable "glue_jobs" {
  description = "Configuración de jobs."
  type = map(object({
    role_arn                   = string
    script_location            = string
    description                = optional(string, "")
    command_name               = optional(string, "glueetl")
    python_version             = optional(string, "3")
    glue_version               = optional(string, "5.0")
    worker_type                = optional(string, "G.1X")
    number_of_workers          = optional(number, 2)
    timeout_minutes            = optional(number, 60)
    max_retries                = optional(number, 0)
    max_concurrent_runs        = optional(number, 1)
    execution_class            = optional(string, null)
    connections                = optional(list(string), [])
    default_arguments          = optional(map(string), {})
    security_configuration_key = optional(string, null)
    additional_tags            = optional(map(string), {})
  }))
  default = {}
}

variable "glue_workflows" {
  description = "Configuración de workflows."
  type = map(object({
    description            = optional(string, "")
    default_run_properties = optional(map(string), {})
    max_concurrent_runs    = optional(number, null)
    additional_tags        = optional(map(string), {})
  }))
  default = {}
}

variable "glue_triggers" {
  description = "Configuración de triggers."
  type = map(object({
    type              = string
    workflow_key      = optional(string, null)
    description       = optional(string, "")
    schedule          = optional(string, null)
    enabled           = optional(bool, true)
    start_on_creation = optional(bool, null)
    event_batching_condition = optional(object({
      batch_size   = number
      batch_window = optional(number, null)
    }), null)
    actions = list(object({
      job_key     = optional(string, null)
      crawler_key = optional(string, null)
      arguments   = optional(map(string), {})
    }))
    predicate = optional(object({
      logical = optional(string, "AND")
      conditions = list(object({
        job_key          = optional(string, null)
        crawler_key      = optional(string, null)
        state            = optional(string, "SUCCEEDED")
        crawl_state      = optional(string, null)
        logical_operator = optional(string, "EQUALS")
      }))
    }), null)
    additional_tags = optional(map(string), {})
  }))
  default = {}
}
