# CallData Foundation Platform - Dev Environment
# All-in-one deployment using shared LiteLLM VPC

locals {
  project_name = "calldata-foundation"
  environment  = "dev"
  region       = "us-east-2"

  # Instance configuration
  instance_type    = "t3.xlarge"
  root_volume_size = 100

  # Security - restrict SIP/RTP to specific IPs in production
  sip_allowed_cidrs = ["0.0.0.0/0"] # TODO: Restrict this
  rtp_allowed_cidrs = ["0.0.0.0/0"] # TODO: Restrict this

  tags = {
    Project     = "CallData Foundation Platform"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Repository  = "calldata-foundation"
  }
}

# Get existing LiteLLM VPC by name tag (shared across all dev services)
data "aws_vpc" "litellm" {
  filter {
    name   = "tag:Name"
    values = ["calldata-litellm-dev-vpc"]
  }
}

# Get public subnets from LiteLLM VPC
data "aws_subnets" "litellm_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.litellm.id]
  }

  filter {
    name   = "tag:Type"
    values = ["public"]
  }
}

# Foundation Platform All-in-One
# Deployed in shared LiteLLM VPC for cost efficiency
module "foundation" {
  source = "../../modules/foundation-aio"

  project_name     = local.project_name
  environment      = local.environment
  vpc_id           = data.aws_vpc.litellm.id
  subnet_id        = tolist(data.aws_subnets.litellm_public.ids)[0]
  instance_type    = local.instance_type
  root_volume_size = local.root_volume_size
  allocate_eip     = true

  # Security
  sip_allowed_cidrs = local.sip_allowed_cidrs
  rtp_allowed_cidrs = local.rtp_allowed_cidrs
}
