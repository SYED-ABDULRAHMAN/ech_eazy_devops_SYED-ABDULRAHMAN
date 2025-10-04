
# Elastic IP (if created)
output "elastic_ip" {
  description = "Elastic IP address (if created)"
  value       = var.create_elastic_ip ? aws_eip.app_eip[0].public_ip : null
}
output "lb_dns_name" {
  value = aws_lb.app_lb.dns_name
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


