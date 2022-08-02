resource "aws_db_subnet_group" "ovr-prod-rds" {
  name       = "ovr-prod-rds"
  subnet_ids = var.private_subnets_db

  tags = {
    Name = "ovr-prod-rds"
  }
}

resource "aws_security_group" "rds" {
  name   = "ovr-prod-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ovr-dev-prod-sg"
  }
}


resource "aws_db_instance" "ovr-prod" {
  identifier             = var.rds_name
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  username               = var.username
  password               = var.rds_password
  multi_az               = true 
  storage_encrypted      = true 
  db_subnet_group_name   = aws_db_subnet_group.ovr-prod-rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible
  skip_final_snapshot    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  deletion_protection    = true
  backup_retention_period = 7
  auto_minor_version_upgrade = false
  monitoring_interval     = 60
  monitoring_role_arn     = var.monitoring_role
  tags = {
    Name        = var.rds_name
    Environment = "production"
  }
  
   
}

resource "aws_db_instance" "db-replica" {

  count                           = 1
  replicate_source_db             = aws_db_instance.ovr-prod.identifier
  identifier                      = "${var.rds_name}-replica"
  allocated_storage               = var.allocated_storage
  iops                            = 0
  engine                          = var.engine
  engine_version                  = var.engine_version
  instance_class                  = var.instance_class
  #name                            = "ovr-rds-prod-replica"
  port                            = 5432
  allow_major_version_upgrade     = true
  apply_immediately               = true
  skip_final_snapshot             = true
  multi_az                        = false
  storage_type                    = "gp2"
  backup_window                   = "03:45-04:15"
  deletion_protection             = false
  final_snapshot_identifier       = "${var.rds_name}-replica-final"
  storage_encrypted               = true 
}

