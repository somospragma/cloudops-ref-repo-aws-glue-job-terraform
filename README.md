# Módulo Terraform: AWS Glue

Módulo de referencia del Chapter CloudOps de Pragma para Glue. Crea bases de datos del Data Catalog, security configurations, crawlers, jobs, workflows y triggers. Todos los recursos usan `for_each` sobre `map(object)`.

## Alcance (PC-IAC-023)

El módulo **no crea** roles IAM, claves KMS, buckets ni scripts. Los recibe por variable:

| Dependencia | Variable | Dominio que la crea |
|---|---|---|
| Rol IAM de crawlers y jobs | `role_arn` | D0 (Security) |
| CMK para security configuration | `kms_key_arn` | D0 (Security) |
| Buckets y script del job | `s3_targets[*].path`, `script_location` | D1/D2 |

## Nomenclatura (PC-IAC-003)

Patrón `{client}-{project}-{environment}-{type}-{key}`:

| Recurso | Tipo | Ejemplo |
|---|---|---|
| Database | `glue-db` (con `_` en lugar de `-`) | `pragma_sopp_dev_glue_db_raw` |
| Security configuration | `glue-sec` | `pragma-sopp-dev-glue-sec-raw` |
| Crawler | `glue-crawler` | `pragma-sopp-dev-glue-crawler-costos` |
| Job | `glue-job` | `pragma-sopp-dev-glue-job-costos` |
| Workflow | `glue-wf` | `pragma-sopp-dev-glue-wf-costos` |
| Trigger | `glue-trg` | `pragma-sopp-dev-glue-trg-start` |

## Patrón evento S3 → EventBridge → Glue

Defina un workflow y un trigger `EVENT`. EventBridge usa `workflow_arns[<clave>]` como target y notifica el evento al workflow, que dispara el crawler y luego el job con triggers `CONDITIONAL`. Ver `sample/terraform.tfvars`.

## Uso

```hcl
module "glue" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-glue-job-terraform.git?ref=v1.0.0"

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
```

## Requisitos

| Nombre | Versión |
|---|---|
| terraform | >= 1.0.0 |
| aws | >= 4.31.0 (alias `aws.project`) |

## Inputs

| Nombre | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `client`, `project`, `environment` | `string` | Sí | Gobernanza y nomenclatura |
| `glue_databases` | `map(object)` | No | Databases del Data Catalog |
| `glue_security_configurations` | `map(object)` | No | Cifrado con CMK |
| `glue_crawlers` | `map(object)` | No | Crawlers sobre S3 |
| `glue_jobs` | `map(object)` | No | Jobs ETL |
| `glue_workflows` | `map(object)` | No | Workflows |
| `glue_triggers` | `map(object)` | No | Triggers `ON_DEMAND`, `SCHEDULED`, `CONDITIONAL`, `EVENT` |

## Outputs

`database_names`, `database_arns`, `security_configuration_names`, `crawler_names`, `crawler_arns`, `job_names`, `job_arns`, `workflow_names`, `workflow_arns`, `trigger_names`, `trigger_arns`.
