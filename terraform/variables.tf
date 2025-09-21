variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t2.micro", "t2.small", "t2.medium", "t2.large"
    ], var.instance_type)
    error_message = "Instance type must be a valid t2 or t3 instance type."
  }
}

# Storage Configuration
variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region where resources will be created"
}

variable "project_name" {
  type        = string
  description = "Project name used for naming resources"
}


# Key Pair Configuration
variable "create_key_pair" {
  description = "Whether to create a new key pair or use an existing one"
  type        = bool
  default     = true
}

variable "existing_key_name" {
  description = "Name of existing key pair (used if create_key_pair is false)"
  type        = string
  default     = ""
}

# Application Configuration
variable "github_repo_url" {
  description = "GitHub repository URL for the application"
  type        = string
  default     = "https://github.com/Trainings-TechEazy/test-repo-for-devops.git"
}

variable "app_port" {
  description = "Port on which the application will run"
  type        = number
  default     = 8080
}

# Elastic IP Configuration
variable "create_elastic_ip" {
  description = "Whether to create and assign an Elastic IP"
  type        = bool
  default     = false
}
