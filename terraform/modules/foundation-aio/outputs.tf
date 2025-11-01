output "instance_id" {
  description = "ID of the Foundation Platform instance"
  value       = aws_instance.foundation.id
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.foundation.private_ip
}

output "instance_public_ip" {
  description = "Public IP address of the instance (if EIP not allocated)"
  value       = aws_instance.foundation.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if allocated)"
  value       = var.allocate_eip ? aws_eip.foundation[0].public_ip : null
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.foundation.id
}

output "ssm_logs_bucket" {
  description = "Name of the S3 bucket for SSM logs"
  value       = aws_s3_bucket.ssm_logs.id
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.foundation_ssm.name
}

output "foundation_url" {
  description = "URL to access the Foundation Platform"
  value       = "https://${var.allocate_eip ? aws_eip.foundation[0].public_ip : aws_instance.foundation.public_ip}"
}
