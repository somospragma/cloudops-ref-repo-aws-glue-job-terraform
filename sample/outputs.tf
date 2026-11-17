# Outputs del ejemplo
output "workflow_arns" {
  description = "ARNs de los workflows de Glue creados."
  value       = module.glue.workflow_arns
}

output "job_names" {
  description = "Nombres de los jobs de Glue creados."
  value       = module.glue.job_names
}

output "database_names" {
  description = "Nombres de las databases de Glue creadas."
  value       = module.glue.database_names
}
