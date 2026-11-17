# Outputs del módulo (PC-IAC-007: granulares, con description)

output "database_names" {
  description = "Mapa clave => nombre de las bases de datos del Glue Data Catalog creadas."
  value       = { for k, v in aws_glue_catalog_database.this : k => v.name }
}

output "database_arns" {
  description = "Mapa clave => ARN de las bases de datos del Glue Data Catalog creadas."
  value       = { for k, v in aws_glue_catalog_database.this : k => v.arn }
}

output "security_configuration_names" {
  description = "Mapa clave => nombre de las security configurations creadas."
  value       = { for k, v in aws_glue_security_configuration.this : k => v.name }
}

output "crawler_names" {
  description = "Mapa clave => nombre de los crawlers creados."
  value       = { for k, v in aws_glue_crawler.this : k => v.name }
}

output "crawler_arns" {
  description = "Mapa clave => ARN de los crawlers creados."
  value       = { for k, v in aws_glue_crawler.this : k => v.arn }
}

output "job_names" {
  description = "Mapa clave => nombre de los jobs creados."
  value       = { for k, v in aws_glue_job.this : k => v.name }
}

output "job_arns" {
  description = "Mapa clave => ARN de los jobs creados."
  value       = { for k, v in aws_glue_job.this : k => v.arn }
}

output "workflow_names" {
  description = "Mapa clave => nombre de los workflows creados."
  value       = { for k, v in aws_glue_workflow.this : k => v.name }
}

output "workflow_arns" {
  description = "Mapa clave => ARN de los workflows. Es el ARN que usa EventBridge como target."
  value       = { for k, v in aws_glue_workflow.this : k => v.arn }
}

output "trigger_names" {
  description = "Mapa clave => nombre de los triggers creados."
  value       = { for k, v in aws_glue_trigger.this : k => v.name }
}

output "trigger_arns" {
  description = "Mapa clave => ARN de los triggers creados."
  value       = { for k, v in aws_glue_trigger.this : k => v.arn }
}
