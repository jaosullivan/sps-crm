resource "random_password" "jwt" {
  length  = 48
  special = false
}

resource "random_password" "admin" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project}/${var.environment}/app"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    APP_ENV        = "production"
    DATABASE_URL   = "postgresql+asyncpg://${var.db_username}:${random_password.db.result}@${aws_db_instance.postgres.address}:5432/${var.db_name}?ssl=require"
    JWT_SECRET     = random_password.jwt.result
    ADMIN_EMAIL    = "admin@stpatrickshk.com"
    ADMIN_PASSWORD = random_password.admin.result
    ADMIN_FULL_NAME = "SPS Admin"
    CORS_ORIGINS   = "https://${var.public_host}"
  })
}
