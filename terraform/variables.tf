variable "environment" {
  type    = string
  default = "dev"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "target_port" {
  type    = number
  default = 80
}

variable "instance_name" {
  type    = string
  default = "techeasy_devops"
}

variable "java_version" {
  type    = string
  default = "21"
}

variable "github_repo" {
  type    = string
  default = "https://github.com/atharva5683/tech_eazy_devops_atharva5683"
}

variable "app_jar_path" {
  type    = string
  default = "target/techeazy-devops-0.0.1-SNAPSHOT.jar"
}

variable "auto_shutdown_minutes" {
  type    = number
  default = 60
}