# Invocación del módulo padre
module "glue" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client      = var.client
  project     = var.project
  environment = var.environment

  glue_databases               = local.glue_databases_transformed
  glue_security_configurations = local.glue_security_configurations_transformed
  glue_crawlers                = local.glue_crawlers_transformed
  glue_jobs                    = local.glue_jobs_transformed
  glue_workflows               = var.glue_workflows
  glue_triggers                = var.glue_triggers
}
