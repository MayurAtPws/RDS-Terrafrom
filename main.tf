provider "aws" {
  region = "us-east-1"
}

#creating a VPC with 2 Subnets 
resource "aws_vpc" "may-rds-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "may-rds-vpc"
  }
}


#The Public Subnet
resource "aws_subnet" "public-subnet-1" {
  vpc_id            = aws_vpc.may-rds-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet-1"
  }
}

#The Private Subnet
resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.may-rds-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-1"
  }
}

# The Private Subnet 2
resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.may-rds-vpc.id
  cidr_block        = "10.0.3.0/24"  
  availability_zone = "us-east-1c"   
  tags = {
    Name = "private-subnet-2"
  }
}

# The SG for RDS Instances
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.may-rds-vpc.id
  name   = "rds_sg"
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

#creating a IAM role for monioring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#creating a role IAM policy
resource "aws_iam_policy" "rds_monitoring_policy" {
  name        = "rds-monitoring-policy"
  description = "Policy to allow RDS to send enhanced monitoring metrics to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

#Attaching the policy to the role
resource "aws_iam_role_policy_attachment" "rds_monitoring_role_policy_attachment" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = aws_iam_policy.rds_monitoring_policy.arn
}

# The DB Subnet Group
resource "aws_db_subnet_group" "may_db_subnet_group" {
  name = "may-db-subnet-group"
  subnet_ids = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]
}

resource "aws_kms_key" "may-kms-key" {
  description = "May KMS Key"
}

#changing Timezone to malaysia
resource "aws_rds_cluster_parameter_group" "may_cluster_parameter_group" {
  name = "may-cluster-parameter-group"
  family = "aurora-postgresql15"
  parameter {
    name = "timezone"
    value = "Asia/Kuala_Lumpur"
  }
}

#cluster configuration
resource "aws_rds_cluster" "may_cluster" {
  cluster_identifier = "may-cluster"
  engine = "aurora-postgresql"
  engine_mode        = "provisioned" #serverless v2
  engine_version = "15.4"
  database_name = "may_database"
  master_username = "may_username"
  master_password = "may_password"
  storage_encrypted = true
  db_subnet_group_name = aws_db_subnet_group.may_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  availability_zones = ["us-east-1b", "us-east-1c"]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.may_cluster_parameter_group.name
  kms_key_id = aws_kms_key.may-kms-key.arn
  #deletion_protection = true
  apply_immediately = true
  iam_database_authentication_enabled = true
  skip_final_snapshot = true
  #Exporting Logs 
  enabled_cloudwatch_logs_exports = ["postgresql"]
  tags = {
    Name = "may-cluster"
  }

  #Serverless v2 Config
  serverlessv2_scaling_configuration {
    max_capacity = 10.0
    min_capacity = 0.5
  }
}

# Read Replica Configuration
resource "aws_rds_cluster_instance" "read_replica" {
  count                = 1
  cluster_identifier   = aws_rds_cluster.may_cluster.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.may_cluster.engine
  engine_version       = aws_rds_cluster.may_cluster.engine_version
  identifier_prefix    = "mayrds-read-replica"
  auto_minor_version_upgrade = true
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn
  monitoring_interval = 5
}

# Write Replica Configuration
resource "aws_rds_cluster_instance" "write_replica" {
  count                = 1
  cluster_identifier   = aws_rds_cluster.may_cluster.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.may_cluster.engine
  engine_version       = aws_rds_cluster.may_cluster.engine_version
  identifier_prefix    = "mayrds-write-replica"
  auto_minor_version_upgrade = true
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn
  monitoring_interval = 5
}

# CloudWatch Logs Export Configuration #optional
resource "aws_cloudwatch_log_group" "may_rds_log_group" {
  name = "/aws/rds/cluster/may-cluster"
}

