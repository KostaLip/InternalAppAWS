resource "aws_secretsmanager_secret" "db_password" {
  provider = aws.management
  name = "lambda/db-password"
}

resource "aws_secretsmanager_secret_version" "db-password" {
  provider = aws.management
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = var.db-password
}