# CallData Foundation Platform - Stage Environment
# All-in-one deployment using cd-stg VPC

locals {
  project_name = "calldata-foundation"
  environment  = "stage"
  region       = "us-east-2"

  # Instance configuration
  instance_type    = "t3.large"   # 2 vCPU, 8GB RAM - sufficient for staging
  root_volume_size = 50           # 50GB sufficient for Wazo + logs

  # Security - restrict SIP/RTP to specific IPs in production
  sip_allowed_cidrs = ["0.0.0.0/0"] # TODO: Restrict this
  rtp_allowed_cidrs = ["0.0.0.0/0"] # TODO: Restrict this

  tags = {
    Project     = "CallData Foundation Platform"
    Environment = "stage"
    ManagedBy   = "Terraform"
    Repository  = "calldata-foundation"
  }
}

# Get existing staging VPC by name tag
data "aws_vpc" "stage" {
  filter {
    name   = "tag:Name"
    values = ["cd-stg"]
  }
}

# Get public subnets from staging VPC
data "aws_subnets" "stage_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.stage.id]
  }

  filter {
    name   = "tag:Type"
    values = ["public"]
  }
}

# Foundation Platform All-in-One
module "foundation" {
  source = "../../modules/foundation-aio"

  project_name     = local.project_name
  environment      = local.environment
  vpc_id           = data.aws_vpc.stage.id
  subnet_id        = tolist(data.aws_subnets.stage_public.ids)[0]
  instance_type    = local.instance_type
  root_volume_size = local.root_volume_size
  allocate_eip     = true

  # Security
  sip_allowed_cidrs = local.sip_allowed_cidrs
  rtp_allowed_cidrs = local.rtp_allowed_cidrs
}
