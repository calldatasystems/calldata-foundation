# Wazo Foundation Platform AMI Builder
# Trigger build: 2024-12-29

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for Packer builder instance"
  default     = "vpc-07d54189eee51b854" # cd-stg VPC
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for Packer builder instance (must be public)"
  default     = "subnet-0605a0a4734c13dd7" # cd-stg public subnet
}

variable "ami_name_prefix" {
  type    = string
  default = "calldata-foundation-wazo"
}

variable "wazo_root_password" {
  type      = string
  sensitive = true
  default   = "P@ssw0rd"
}

locals {
  timestamp = formatdate("YYYYMMDD-hhmmss", timestamp())
}

source "amazon-ebs" "wazo" {
  ami_name        = "${var.ami_name_prefix}-${local.timestamp}"
  ami_description = "CallData Foundation Platform - Wazo UC with IVR plugins"
  instance_type   = var.instance_type
  region          = var.aws_region

  # VPC and subnet configuration (no default VPC in us-east-2)
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true

  source_ami_filter {
    filters = {
      name                = "debian-12-amd64-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["136693071363"] # Official Debian
  }

  ssh_username = "admin"

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.ami_name_prefix}-${local.timestamp}"
    Project     = "CallData Foundation"
    Component   = "Wazo Platform"
    BuildDate   = local.timestamp
    ManagedBy   = "Packer"
  }

  run_tags = {
    Name = "packer-builder-wazo-foundation"
  }
}

build {
  name    = "wazo-foundation"
  sources = ["source.amazon-ebs.wazo"]

  # Wait for cloud-init to complete
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init...'",
      "cloud-init status --wait || true",
      "sleep 30"
    ]
  }

  # Copy installation scripts
  provisioner "file" {
    source      = "scripts/"
    destination = "/tmp/"
  }

  # Run Wazo installation (plugins installed separately for testing)
  provisioner "shell" {
    environment_vars = [
      "WAZO_ROOT_PASSWORD=${var.wazo_root_password}",
      "DEBIAN_FRONTEND=noninteractive"
    ]
    scripts = [
      "scripts/01-base-setup.sh",
      "scripts/02-install-wazo.sh",
      "scripts/04-configure-wazo.sh",
      "scripts/05-cleanup.sh"
    ]
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
