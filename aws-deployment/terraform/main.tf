terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source for existing Elastic IP
data "aws_eip" "existing" {
  public_ip = var.elastic_ip
}

# Security Group for the application
resource "aws_security_group" "clash_tracker_sg" {
  name_prefix = "clash-tracker-"
  description = "Security group for Clash War Tracker application"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access for frontend
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Spring Boot backend
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Spring Boot backend"
  }

  # React frontend (development)
  ingress {
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "React development server"
  }

  # PostgreSQL (if using RDS)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "PostgreSQL access"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "clash-tracker-security-group"
  }
}

# Launch EC2 instance
resource "aws_instance" "clash_tracker" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.clash_tracker_sg.id]

  user_data = base64encode(file("${path.module}/simple-user-data.sh"))

  tags = {
    Name = "clash-war-tracker"
  }
}

# Associate existing Elastic IP with the instance
resource "aws_eip_association" "clash_tracker_eip" {
  instance_id   = aws_instance.clash_tracker.id
  allocation_id = data.aws_eip.existing.id
}

# RDS Subnet Group for multi-AZ deployment
resource "aws_db_subnet_group" "clash_tracker_subnet_group" {
  count = var.create_rds ? 1 : 0
  
  name       = "clash-tracker-subnet-group"
  subnet_ids = data.aws_subnets.default[0].ids

  tags = {
    Name = "clash-tracker-db-subnet-group"
  }
}

# Data source for default VPC subnets
data "aws_vpc" "default" {
  count = var.create_rds ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.create_rds ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

# Security Group specifically for RDS
resource "aws_security_group" "rds_sg" {
  count = var.create_rds ? 1 : 0
  
  name_prefix = "clash-tracker-rds-"
  description = "Security group for Clash Tracker RDS PostgreSQL"

  # PostgreSQL access from EC2 security group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.clash_tracker_sg.id]
    description     = "PostgreSQL access from EC2"
  }

  # PostgreSQL access from your local IP (for management)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${var.elastic_ip}/32"]
    description = "PostgreSQL access from Elastic IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "clash-tracker-rds-security-group"
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "clash_tracker_db" {
  count = var.create_rds ? 1 : 0

  identifier     = "clash-tracker-db"
  engine         = "postgres"
  engine_version = "15.7"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "clash_tracker"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg[0].id]
  db_subnet_group_name   = aws_db_subnet_group.clash_tracker_subnet_group[0].name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false
  
  # Enable performance insights (optional)
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  tags = {
    Name = "clash-tracker-database"
  }
}

# Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.clash_tracker.id
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = data.aws_eip.existing.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.clash_tracker.public_dns
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.create_rds ? aws_db_instance.clash_tracker_db[0].endpoint : "Not created"
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.create_rds ? aws_db_instance.clash_tracker_db[0].port : "Not created"
}

output "rds_database_name" {
  description = "RDS database name"
  value       = var.create_rds ? aws_db_instance.clash_tracker_db[0].db_name : "Not created"
}

output "rds_username" {
  description = "RDS master username"
  value       = var.create_rds ? aws_db_instance.clash_tracker_db[0].username : "Not created"
  sensitive   = true
}
