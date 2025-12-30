variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 100
}

variable "allocate_eip" {
  description = "Whether to allocate and associate an Elastic IP"
  type        = bool
  default     = true
}

variable "sip_allowed_cidrs" {
  description = "CIDR blocks allowed to connect via SIP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "rtp_allowed_cidrs" {
  description = "CIDR blocks allowed for RTP media"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_alb" {
  description = "Enable Application Load Balancer for scalability"
  type        = bool
  default     = false
}

variable "alb_subnet_ids" {
  description = "List of subnet IDs for ALB (requires at least 2 AZs)"
  type        = list(string)
  default     = []
}

variable "domain_name" {
  description = "Domain name for ACM certificate (e.g., stage.foundation.calldata.app)"
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for DNS validation"
  type        = string
  default     = ""
}

variable "custom_ami_id" {
  description = "Custom AMI ID with Wazo pre-installed. If empty, uses latest Debian and installs via Ansible."
  type        = string
  default     = ""
}

variable "use_custom_ami" {
  description = "Whether to use custom AMI (true) or base Debian with Ansible (false)"
  type        = bool
  default     = false
}
