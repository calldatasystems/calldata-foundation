# Outputs for Foundation Platform Dev Environment

output "foundation_instance_id" {
  description = "ID of the Foundation Platform instance"
  value       = module.foundation.instance_id
}

output "foundation_private_ip" {
  description = "Private IP address of the instance"
  value       = module.foundation.instance_private_ip
}

output "foundation_public_ip" {
  description = "Public Elastic IP address"
  value       = module.foundation.elastic_ip
}

output "foundation_url" {
  description = "URL to access the Foundation Platform"
  value       = module.foundation.foundation_url
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.foundation.security_group_id
}

output "ssm_logs_bucket" {
  description = "Name of the S3 bucket for SSM logs"
  value       = module.foundation.ssm_logs_bucket
}

output "iam_role_name" {
  description = "Name of the IAM role for SSM access"
  value       = module.foundation.iam_role_name
}

output "vpc_id" {
  description = "ID of the shared VPC"
  value       = data.aws_vpc.litellm.id
}

output "subnet_id" {
  description = "ID of the subnet used"
  value       = tolist(data.aws_subnets.litellm_public.ids)[0]
}
