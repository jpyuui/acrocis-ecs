# =================
# RDS Cluster
# =================
resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-subnet-group-${var.env}"
  description = "database-subnet-group for ${var.name}-${var.env}"
  subnet_ids  = var.subnet_ids
}

data "aws_ssm_parameter" "username" {
  name            = var.ssm_db_username_name
  with_decryption = true
}

resource "aws_rds_cluster" "this" {
  cluster_identifier           = "${var.name}-rds-cluster-${var.env}"
  database_name                = "${var.name}_db_${var.env}"
  engine                       = var.engine
  engine_version               = var.engine_version
  port                         = var.port
  master_username              = data.aws_ssm_parameter.username.value
  master_password              = "temporary_password"
  preferred_backup_window      = "09:10-09:40"
  preferred_maintenance_window = "wed:09:45-wed:10:45"
  skip_final_snapshot          = false
  deletion_protection          = true

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name
  db_subnet_group_name            = aws_db_subnet_group.this.name
  availability_zones              = var.availability_zones
  vpc_security_group_ids = [
    var.security_group_id,
  ]

  lifecycle {
    ignore_changes = [
      master_password,
      availability_zones,
    ]
  }
}

resource "aws_rds_cluster_instance" "this" {
  count = length(var.instance_names)

  identifier           = "${var.name}-db-instance-${var.env}-${var.instance_names[count.index]}"
  cluster_identifier   = aws_rds_cluster.this.id
  engine               = aws_rds_cluster.this.engine
  instance_class       = var.instance_class
  db_subnet_group_name = aws_db_subnet_group.this.name
}

resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.name}-${var.env}"
  family = var.family

  parameter {
    name         = "time_zone"
    value        = var.timezone
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_client"
    value        = var.char_code
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_connection"
    value        = var.char_code
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_database"
    value        = var.char_code
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_results"
    value        = var.char_code
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_server"
    value        = var.char_code
    apply_method = "immediate"
  }
}

resource "null_resource" "modify_password_on_cluster_created" {
  triggers = {
    cluster_id = aws_rds_cluster.this.id
  }

  provisioner "local-exec" {
    command    = "aws ssm get-parameter --name ${var.ssm_db_password_name} --query 'Parameter.Value' --with-decryption | xargs -IPASS aws rds modify-db-cluster --db-cluster-identifier ${aws_rds_cluster.this.id} --master-user-password PASS --apply-immediately"
    on_failure = fail
  }
}
