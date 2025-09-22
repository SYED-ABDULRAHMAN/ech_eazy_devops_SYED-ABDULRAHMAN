# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "techeazy-devops"
environment  = "dev"

# Network Configuration
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"

# Security Configuration
# Accessible from anywhere as requested
allowed_ssh_cidr  = ["0.0.0.0/0"]
allowed_http_cidr = ["0.0.0.0/0"]

# EC2 Configuration
instance_type = "t2.micro"

# Storage Configuration
root_volume_type = "gp3"
root_volume_size = 20

# Key Pair Configuration
# Creating new key pair as requested
create_key_pair    = false
existing_key_name  = "techeazy-devops-key"

# Application Configuration
github_repo_url = "https://github.com/Trainings-TechEazy/test-repo-for-devops.git"
app_port       = 8080

# Elastic IP Configuration
create_elastic_ip = false
