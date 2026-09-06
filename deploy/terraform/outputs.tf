output "region" {
  value = var.aws_region
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_api_repository_url" {
  value = aws_ecr_repository.api.repository_url
}

output "ecr_web_repository_url" {
  value = aws_ecr_repository.web.repository_url
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "secrets_manager_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "public_host" {
  value = var.public_host
}

output "database_url_template" {
  description = "Fill password from Secrets Manager; use ssl=require"
  value       = "postgresql+asyncpg://${var.db_username}:PASSWORD@${aws_db_instance.postgres.address}:5432/${var.db_name}?ssl=require"
}
