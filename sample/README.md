# Ejemplo de Uso del Módulo

Invoca el módulo padre (`source = "../"`) con un workflow `EVENT` que ejecuta un crawler y luego un job.

1. Ajuste `terraform.tfvars`. Los campos `role_arn`, `kms_key_arn` y `script_location` se dejan vacíos y se inyectan desde `data.tf` (PC-IAC-026).
2. `terraform init && terraform fmt && terraform validate && terraform plan`

Flujo de datos: `terraform.tfvars -> variables.tf -> data.tf -> locals.tf -> main.tf -> ../`
