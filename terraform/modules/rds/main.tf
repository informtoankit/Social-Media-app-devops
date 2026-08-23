# DB Subnet Group — batata hai RDS ko kaunsi private subnets use karni hain
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Random password generate karta hai (secure, hardcoded nahi)
resource "random_password" "db_password" {
  length  = 20
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Password ko Secrets Manager mein securely store karta hai
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}-db-credentials"
  description = "RDS PostgreSQL credentials for ${var.project_name}"

  tags = {
    Name = "${var.project_name}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = var.db_name
  })
}

# Actual RDS Database Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "16.3"

  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]

  multi_az            = var.multi_az
  publicly_accessible = false

  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-final-snapshot"

  deletion_protection = var.deletion_protection

  tags = {
    Name = "${var.project_name}-db"
  }
}
module "rds" {
  source = "./modules/rds"

  project_name           = var.project_name
  private_subnet_ids     = module.vpc.private_subnet_ids
  rds_security_group_id  = module.security.rds_security_group_id
  db_instance_class      = var.db_instance_class
  multi_az                = var.rds_multi_az
}