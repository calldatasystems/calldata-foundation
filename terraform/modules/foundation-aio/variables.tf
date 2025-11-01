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
