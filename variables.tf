# Variables de entrada del módulo

############################################################################
# Gobernanza (PC-IAC-002)
############################################################################
variable "client" {
  description = "Nombre del cliente o unidad de negocio. Usado en la nomenclatura de recursos."
  type        = string

  validation {
    condition     = length(var.client) > 0 && can(regex("^[a-z0-9]+$", var.client))
    error_message = "client no puede estar vacío y debe ser alfanumérico en minúsculas."
  }
}

variable "project" {
  description = "Nombre del proyecto. Usado en la nomenclatura de recursos."
  type        = string

  validation {
    condition     = length(var.project) > 0 && can(regex("^[a-z0-9]+$", var.project))
    error_message = "project no puede estar vacío y debe ser alfanumérico en minúsculas."
  }
}

variable "environment" {
  description = "Entorno de despliegue (dev, qa, pdn, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "pdn", "prod"], var.environment)
    error_message = "environment debe ser uno de: dev, qa, pdn, prod."
  }
}

############################################################################
# Glue Data Catalog
############################################################################
variable "glue_databases" {
  description = "Mapa de bases de datos del Glue Data Catalog. La clave se usa en la nomenclatura."
  type = map(object({
    description     = optional(string, "")
    location_uri    = optional(string, null)
    additional_tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.glue_databases : can(regex("^[a-z0-9-]{1,40}$", k))])
    error_message = "Las claves de glue_databases deben ser minúsculas, números o guiones (máx 40 caracteres)."
  }
}

############################################################################
# Security configurations (cifrado en reposo, PC-IAC-020)
############################################################################
variable "glue_security_configurations" {
  description = "Mapa de security configurations de Glue. kms_key_arn debe ser una CMK recibida desde el Root."
  type = map(object({
    kms_key_arn                   = string
    cloudwatch_encryption_mode    = optional(string, "SSE-KMS")
    job_bookmarks_encryption_mode = optional(string, "CSE-KMS")
    s3_encryption_mode            = optional(string, "SSE-KMS")
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.glue_security_configurations : startswith(v.kms_key_arn, "arn:aws:kms:")])
    error_message = "kms_key_arn debe ser el ARN de una CMK (arn:aws:kms:...)."
  }

  validation {
    condition = alltrue([
      for k, v in var.glue_security_configurations :
      contains(["DISABLED", "SSE-KMS"], v.cloudwatch_encryption_mode) &&
      contains(["DISABLED", "CSE-KMS"], v.job_bookmarks_encryption_mode) &&
      contains(["DISABLED", "SSE-KMS", "SSE-S3"], v.s3_encryption_mode)
    ])
    error_message = "Modos de cifrado inválidos. CloudWatch: DISABLED|SSE-KMS. Bookmarks: DISABLED|CSE-KMS. S3: DISABLED|SSE-KMS|SSE-S3."
  }
}

############################################################################
# Crawlers
############################################################################
variable "glue_crawlers" {
  description = "Mapa de crawlers de Glue. Use database_key para una base creada por el módulo o database_name para una existente."
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

  validation {
    condition     = alltrue([for k, v in var.glue_crawlers : startswith(v.role_arn, "arn:aws:iam::")])
    error_message = "role_arn debe ser el ARN de un rol IAM (arn:aws:iam::...)."
  }

  validation {
    condition     = alltrue([for k, v in var.glue_crawlers : (v.database_key != null) != (length(v.database_name) > 0)])
    error_message = "Cada crawler debe definir exactamente uno de: database_key o database_name."
  }

  validation {
    condition     = alltrue([for k, v in var.glue_crawlers : length(v.s3_targets) > 0 && alltrue([for t in v.s3_targets : startswith(t.path, "s3://")])])
    error_message = "Cada crawler requiere al menos un s3_target y cada path debe iniciar con s3://."
  }

  validation {
    condition     = alltrue([for k, v in var.glue_crawlers : contains(["CRAWL_EVERYTHING", "CRAWL_NEW_FOLDERS_ONLY", "CRAWL_EVENT_MODE"], v.recrawl_behavior)])
    error_message = "recrawl_behavior debe ser CRAWL_EVERYTHING, CRAWL_NEW_FOLDERS_ONLY o CRAWL_EVENT_MODE."
  }
}

############################################################################
# Jobs
############################################################################
variable "glue_jobs" {
  description = "Mapa de jobs de Glue. El rol IAM y el script en S3 se reciben desde el Root."
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

  validation {
    condition     = alltrue([for k, v in var.glue_jobs : startswith(v.role_arn, "arn:aws:iam::")])
    error_message = "role_arn debe ser el ARN de un rol IAM (arn:aws:iam::...)."
  }

  validation {
    condition     = alltrue([for k, v in var.glue_jobs : startswith(v.script_location, "s3://")])
    error_message = "script_location debe iniciar con s3://."
  }

  validation {
    condition     = alltrue([for k, v in var.glue_jobs : contains(["glueetl", "pythonshell", "gluestreaming"], v.command_name)])
    error_message = "command_name debe ser glueetl, pythonshell o gluestreaming."
  }

  validation {
    condition     = alltrue([for k, v in var.glue_jobs : contains(["G.025X", "G.1X", "G.2X", "G.4X", "G.8X", "Z.2X"], v.worker_type)])
    error_message = "worker_type inválido. Valores: G.025X, G.1X, G.2X, G.4X, G.8X, Z.2X."
  }

  validation {
    condition     = alltrue([for k, v in var.glue_jobs : v.number_of_workers >= 2 && v.timeout_minutes > 0 && v.max_retries >= 0])
    error_message = "number_of_workers debe ser >= 2, timeout_minutes > 0 y max_retries >= 0."
  }
}

############################################################################
# Workflows
############################################################################
variable "glue_workflows" {
  description = "Mapa de workflows de Glue. Un workflow con trigger tipo EVENT puede ser iniciado por EventBridge."
  type = map(object({
    description            = optional(string, "")
    default_run_properties = optional(map(string), {})
    max_concurrent_runs    = optional(number, null)
    additional_tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.glue_workflows : v.max_concurrent_runs == null || v.max_concurrent_runs >= 1])
    error_message = "max_concurrent_runs debe ser null o >= 1."
  }
}

############################################################################
# Triggers
############################################################################
variable "glue_triggers" {
  description = "Mapa de triggers de Glue. Las acciones y condiciones referencian jobs y crawlers por su clave en este módulo."
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

  validation {
    condition     = alltrue([for k, v in var.glue_triggers : contains(["ON_DEMAND", "SCHEDULED", "CONDITIONAL", "EVENT"], v.type)])
    error_message = "type debe ser ON_DEMAND, SCHEDULED, CONDITIONAL o EVENT."
  }

  validation {
    condition     = alltrue([for k, v in var.glue_triggers : length(v.actions) > 0 && alltrue([for a in v.actions : (a.job_key != null) != (a.crawler_key != null)])])
    error_message = "Cada trigger requiere al menos una acción, y cada acción define exactamente uno de: job_key o crawler_key."
  }

  validation {
    condition = alltrue([
      for k, v in var.glue_triggers :
      (v.type != "SCHEDULED" || v.schedule != null) &&
      (v.type != "CONDITIONAL" || v.predicate != null) &&
      (v.type != "EVENT" || v.workflow_key != null)
    ])
    error_message = "SCHEDULED requiere schedule, CONDITIONAL requiere predicate y EVENT requiere workflow_key."
  }
}
