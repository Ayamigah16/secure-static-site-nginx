output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = var.use_elastic_ip ? aws_eip.web_server[0].public_ip : aws_instance.web_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.web_server.id
}

output "ssh_connection_string" {
  description = "SSH connection command"
  value       = "ssh -i ~/.ssh/${local.key_pair_name} ${var.deploy_user}@${var.use_elastic_ip ? aws_eip.web_server[0].public_ip : aws_instance.web_server.public_ip}"
}

output "key_pair_name" {
  description = "Name of the SSH key pair being used"
  value       = local.key_pair_name
}

output "elastic_ip" {
  description = "Elastic IP address (if enabled)"
  value       = var.use_elastic_ip ? aws_eip.web_server[0].public_ip : null
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}
