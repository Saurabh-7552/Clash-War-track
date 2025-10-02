# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"  # Stockholm region (based on your IP)
}

variable "elastic_ip" {
  description = "Existing Elastic IP address"
  type        = string
  default     = "13.48.112.177"
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0014ce3e52359afbd"  # Amazon Linux 2023 in eu-north-1
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
  # You need to provide this
}

# Application Configuration
variable "clash_api_key" {
  description = "Clash of Clans API key for the Elastic IP"
  type        = string
  sensitive   = true
  # You need to provide this after creating it for IP 13.48.112.177
}

# Database Configuration
variable "create_rds" {
  description = "Whether to create RDS PostgreSQL instance"
  type        = bool
  default     = false  # Set to true if you want AWS-managed database
}

variable "db_host" {
  description = "Database host"
  type        = string
  default     = "localhost"  # Use RDS endpoint if create_rds = true
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "verma2017"  # Change this for production
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "clashtrack.ai"
}
