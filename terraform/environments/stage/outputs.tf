# Outputs for Foundation Platform Stage Environment

output "foundation_instance_id" {
  description = "ID of the Foundation Platform instance"
  value       = module.foundation.instance_id
}

output "foundation_private_ip" {
  description = "Private IP address of the instance"
  value       = module.foundation.instance_private_ip
}

output "foundation_public_ip" {
  description = "Public Elastic IP address (for SIP traffic)"
  value       = module.foundation.elastic_ip
}

output "foundation_url" {
  description = "URL to access the Foundation Platform"
  value       = module.foundation.foundation_url
}

output "foundation_domain" {
  description = "Domain URL to access the Foundation Platform"
  value       = "https://stage.foundation.calldata.app"
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
  description = "ID of the staging VPC"
  value       = data.aws_vpc.stage.id
}

output "subnet_id" {
  description = "ID of the subnet used"
  value       = tolist(data.aws_subnets.stage_public.ids)[0]
}

# ALB outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.foundation.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.foundation.alb_arn
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = module.foundation.target_group_arn
}
