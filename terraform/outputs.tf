# Instance Information
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.app_server.public_dns
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.app_server.private_ip
}

# Elastic IP (if created)
output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.create_elastic_ip ? aws_eip.app_eip[0].public_ip : null
}

# Application URLs
output "application_url_http" {
  description = "HTTP URL to access the application"
  value       = "http://${aws_instance.app_server.public_ip}:${var.app_port}"
}

output "application_url_http_port_80" {
  description = "HTTP URL to access the application on port 80"
  value       = "http://${aws_instance.app_server.public_ip}"
}

# SSH Connection
output "ssh_connection_command" {
  description = "Command to SSH into the instance"
  value       = var.create_key_pair ? "ssh -i ${var.project_name}-key.pem ubuntu@${aws_instance.app_server.public_ip}" : "ssh -i YOUR_KEY.pem ubuntu@${aws_instance.app_server.public_ip}"
}

# Security Group
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.app_sg.id
}

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

# Key Pair Information
output "key_pair_name" {
  description = "Name of the key pair"
  value       = var.create_key_pair ? aws_key_pair.app_key[0].key_name : var.existing_key_name
}

output "private_key_file" {
  description = "Path to the private key file (if created)"
  value       = var.create_key_pair ? "${var.project_name}-key.pem" : "Using existing key pair"
}


