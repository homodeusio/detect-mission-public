
resource "aws_rds_global_cluster" "globaldb" {
  provider                  = aws.primary
  global_cluster_identifier = "detect-globaldb"
  engine                    = "aurora-postgresql"
  engine_version            = "13.5"
  database_name             = "detect"
  storage_encrypted         = false
}

resource "aws_rds_cluster" "primary" {
  provider                  = aws.primary
  global_cluster_identifier = aws_rds_global_cluster.globaldb.id
  cluster_identifier        = "detect-ue1"
  engine                    = "aurora-postgresql"
  engine_version            = "13.5"
  availability_zones        = ["us-east-1a", "us-east-1b", "us-east-1c"]
  db_subnet_group_name      = aws_db_subnet_group.private_p.name
  port                      = "5432"
  database_name             = "detect"
  master_username           = "root"
  master_password           = "mysecurepassword"
  backup_retention_period   = 30
  storage_encrypted         = true
  kms_key_id                = "xxxxxxxxxxxxx"
  apply_immediately         = true
  skip_final_snapshot       = true
  lifecycle {
    ignore_changes = [
      replication_source_identifier,
    ]
  }
}

resource "aws_rds_cluster_instance" "primary" {
  count                = 2
  provider             = aws.primary
  identifier           = "detect-ue1-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.primary.id
  engine               = aws_rds_cluster.primary.engine
  engine_version       = "13.5"
  instance_class       = "db.r5.large"
  db_subnet_group_name = aws_db_subnet_group.private_p.name
  apply_immediately    = true
}

resource "aws_rds_cluster" "secondary" {
  provider                  = aws.secondary
  global_cluster_identifier = aws_rds_global_cluster.globaldb.id
  cluster_identifier        = "detect-ue2"
  engine                    = "aurora-postgresql"
  engine_version            = "13.5"
  availability_zones        = ["us-east-2a", "us-east-2b", "us-east-2c"]
  db_subnet_group_name      = aws_db_subnet_group.private_s.name
  backup_retention_period   = 30
  port                      = "5432"
  apply_immediately         = true
  skip_final_snapshot       = true
  depends_on = [
    aws_rds_cluster_instance.primary,
  ]
  lifecycle {
    ignore_changes = [
      replication_source_identifier,
    ]
  }
}

resource "aws_rds_cluster_instance" "secondary" {
  count                = 2
  provider             = aws.secondary
  identifier           = "detect-ue2-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.secondary.id
  engine               = aws_rds_cluster.secondary.engine
  engine_version       = "13.5"
  instance_class       = "db.r5.large"
  db_subnet_group_name = aws_db_subnet_group.private_s.name
  apply_immediately    = true
}

resource "aws_db_subnet_group" "private_p" {
  provider   = aws.primary
  name       = "detect-sg"
  subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxxxx"]
}

resource "aws_db_subnet_group" "private_s" {
  provider   = aws.secondary
  name       = "detect-sg-ue2"
  subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxxxx"]
}

//backups
resource "aws_backup_vault" "detect-db" {
  provider    = aws.primary
  name        = "detect-db"
  kms_key_arn = "arn:aws:kms:us-east-1:xxxxxxxxxx:key/xxxxxxxxxxx"
}

resource "aws_backup_vault" "detect-db-copy" {
  provider    = aws.secondary
  name        = "detect-db-copy"
  kms_key_arn = "arn:aws:kms:us-east-2:xxxxxxxxxx:key/xxxxxxxxxx"
}

resource "aws_backup_plan" "detect-db-plan" {
  provider = aws.primary
  name     = "detect-db-plan"

  rule {
    rule_name         = "detect-db-rule"
    target_vault_name = aws_backup_vault.detect-db.name
    schedule          = "cron(0 2 * * ? *)"

    lifecycle {
      cold_storage_after = 30
      delete_after       = 180
    }

    copy_action {
      lifecycle {
        cold_storage_after = 30
        delete_after       = 180
      }
      destination_vault_arn = aws_backup_vault.detect-db-copy.arn
    }
  }
}

resource "aws_iam_role" "detect-backup-role" {
  provider           = aws.primary
  name               = "detect-backup-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "detect-backup-role-attachment" {
  provider   = aws.primary
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.detect-backup-role.name
}

resource "aws_backup_selection" "detect-backup-selection" {
  provider     = aws.primary
  iam_role_arn = aws_iam_role.detect-backup-role.arn
  name         = "detect-backup-selection"
  plan_id      = aws_backup_plan.detect-db-plan.id

  resources = [
    aws_rds_cluster.primary.arn
  ]
}