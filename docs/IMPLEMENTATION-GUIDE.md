# CallData Foundation Platform - Implementation Guide

## Overview

This guide provides step-by-step instructions for building the CallData Foundation Platform from scratch, based on lessons learned from the aws-saas-ui deployment.

**Important**: This is a **replacement** for the all-in-one Wazo deployment, not an add-on.

## Prerequisites

- AWS Account with administrative access
- GitHub account and organization
- Local development machine with:
  - Git 2.30+
  - Terraform 1.5+
  - Ansible 8.7+
  - AWS CLI v2
  - Python 3.9+
  - Docker (optional, for local testing)

## Phase 1: Repository Setup

### Step 1.1: Create Main Repository

```bash
# Navigate to your projects directory
cd /mnt/c/Users/aqorn/Documents/CODE

# Create repository
mkdir -p calldata-foundation
cd calldata-foundation

# Initialize git
git init
git checkout -b main
```

### Step 1.2: Create Directory Structure

```bash
# Create all directories
mkdir -p .github/workflows
mkdir -p terraform/{modules,environments}
mkdir -p terraform/modules/{networking,database,message-bus,foundation-ui,foundation-auth,foundation-confd,foundation-calld,foundation-asterisk}
mkdir -p terraform/environments/{dev,staging,prod}
mkdir -p ansible/{inventories,roles,playbooks}
mkdir -p ansible/inventories/{dev,staging,prod}
mkdir -p ansible/roles/{foundation-ui,foundation-auth,foundation-confd,foundation-calld,foundation-asterisk,foundation-database,foundation-monitoring}
mkdir -p docker/{foundation-ui,foundation-auth,foundation-confd,foundation-calld}
mkdir -p scripts
mkdir -p docs

# Create placeholder files
touch README.md
touch LICENSE
touch .gitignore
```

### Step 1.3: Create .gitignore

```bash
cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
.terraform/
.terraform.lock.hcl
crash.log
override.tf
override.tf.json

# Ansible
*.retry
ansible/inventories/*/hosts
ansible/inventories/*/group_vars/vault.yml
.vault_pass

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Secrets
*.pem
*.key
secrets/

# Local development
.env
.env.local
docker-compose.override.yml
EOF
```

### Step 1.4: Add Git Submodules

```bash
# Add calldata-platform (custom UI fork)
git submodule add https://github.com/YOUR-ORG/calldata-platform.git platform-ui

# Add foundation-ui-plugins
git submodule add https://github.com/YOUR-ORG/foundation-ui-plugins.git platform-plugins

# (Optional) Add wazo-ansible for reference
git submodule add https://github.com/wazo-platform/wazo-ansible.git reference/wazo-ansible
```

### Step 1.5: Create README.md

```markdown
# CallData Foundation Platform

Automated deployment system for CallData Foundation Platform with custom UI and plugins.

## Architecture

This is a complete replacement for all-in-one Wazo deployments, offering:

- Custom branded UI (calldata-platform)
- Extensible plugin system (foundation-ui-plugins)
- Microservices deployment options
- High availability support
- Full observability stack

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architecture documentation.

## Quick Start

### Prerequisites

- AWS Account
- Terraform 1.5+
- Ansible 8.7+
- AWS CLI v2

### Deploy to Dev

\`\`\`bash
# Clone repository
git clone --recursive https://github.com/YOUR-ORG/calldata-foundation.git
cd calldata-foundation

# Configure AWS credentials
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_REGION=us-east-2

# Deploy infrastructure
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# Deploy application
cd ../../../ansible
ansible-playbook -i inventories/dev/hosts playbooks/deploy-all.yml
\`\`\`

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Development Guide](docs/DEVELOPMENT.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [API Documentation](docs/API.md)

## Repository Structure

```
calldata-foundation/
├── terraform/          # Infrastructure as Code
├── ansible/            # Configuration management
├── docker/             # Container definitions
├── platform-ui/        # Custom UI (submodule)
├── platform-plugins/   # Custom plugins (submodule)
├── scripts/            # Utility scripts
└── docs/               # Documentation
```

## License

Proprietary - CallData
```

## Phase 2: Terraform Infrastructure (Dev Environment - All-in-One)

### Step 2.1: Create Networking Module

```bash
cd terraform/modules/networking
```

Create `main.tf`:

```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# Public Subnets (one per AZ)
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Type = "public"
  }
}

# Private Subnets (one per AZ)
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Type = "private"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways (one per AZ for HA)
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Tables for Private Subnets (one per AZ)
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
  }
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "private" {
  count = var.enable_nat_gateway ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-flow-logs"
  }
}

# CloudWatch Log Group for Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-flow-logs"
  }
}

# IAM Role for Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project_name}-${var.environment}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Flow Logs
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project_name}-${var.environment}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
```

Create `variables.tf`:

```hcl
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}
```

Create `outputs.tf`:

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT gateways"
  value       = aws_eip.nat[*].public_ip
}
```

### Step 2.2: Create Foundation All-in-One Module (Dev)

```bash
cd terraform/modules/foundation-aio
```

Create `main.tf`:

```hcl
# Copy and adapt from aws-saas-ui/terraform/modules/wazo/main.tf
# This module creates a single EC2 instance with all components

data "aws_ami" "debian_bookworm" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for SSM
resource "aws_iam_role" "foundation_ssm" {
  name = "${var.project_name}-${var.environment}-foundation-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.foundation_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "foundation" {
  name = "${var.project_name}-${var.environment}-foundation-profile"
  role = aws_iam_role.foundation_ssm.name
}

# S3 bucket for SSM logs
resource "aws_s3_bucket" "ssm_logs" {
  bucket = "${var.project_name}-${var.environment}-ssm-logs"
}

resource "aws_s3_bucket_versioning" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role_policy" "ssm_s3" {
  name = "${var.project_name}-${var.environment}-ssm-s3-policy"
  role = aws_iam_role.foundation_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.ssm_logs.arn,
        "${aws_s3_bucket.ssm_logs.arn}/*"
      ]
    }]
  })
}

# Security Group
resource "aws_security_group" "foundation" {
  name        = "${var.project_name}-${var.environment}-foundation-sg"
  description = "Security group for CallData Foundation Platform"
  vpc_id      = var.vpc_id

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (redirect to HTTPS)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SIP (UDP)
  ingress {
    description = "SIP UDP"
    from_port   = 5060
    to_port     = 5060
    protocol    = "udp"
    cidr_blocks = var.sip_allowed_cidrs
  }

  # SIP (TCP)
  ingress {
    description = "SIP TCP"
    from_port   = 5060
    to_port     = 5060
    protocol    = "tcp"
    cidr_blocks = var.sip_allowed_cidrs
  }

  # RTP
  ingress {
    description = "RTP"
    from_port   = 10000
    to_port     = 20000
    protocol    = "udp"
    cidr_blocks = var.rtp_allowed_cidrs
  }

  # Egress - allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-foundation-sg"
  }
}

# EC2 Instance
resource "aws_instance" "foundation" {
  ami                    = data.aws_ami.debian_bookworm.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.foundation.id]
  iam_instance_profile   = aws_iam_instance_profile.foundation.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Disable automatic updates
              echo 'APT::Periodic::Update-Package-Lists "0";' > /etc/apt/apt.conf.d/20auto-upgrades
              echo 'APT::Periodic::Unattended-Upgrade "0";' >> /etc/apt/apt.conf.d/20auto-upgrades

              systemctl stop unattended-upgrades.service || true
              systemctl disable unattended-upgrades.service || true
              systemctl mask unattended-upgrades.service || true

              # Install SSM agent
              cd /tmp
              curl -o amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
              dpkg -i amazon-ssm-agent.deb || true
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent

              # Create admin user
              if ! id -u admin > /dev/null 2>&1; then
                useradd -m -s /bin/bash admin
              fi
              mkdir -p /home/admin/.ssh
              chmod 700 /home/admin/.ssh
              chown -R admin:admin /home/admin/.ssh

              echo "admin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/admin
              chmod 440 /etc/sudoers.d/admin

              touch /var/lib/cloud/instance/boot-finished
              EOF

  user_data_replace_on_change = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-foundation"
    Environment = var.environment
    Component   = "foundation-platform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm_policy,
    aws_iam_role_policy.ssm_s3
  ]
}

# Elastic IP
resource "aws_eip" "foundation" {
  count  = var.allocate_eip ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-foundation-eip"
  }
}

resource "aws_eip_association" "foundation" {
  count         = var.allocate_eip ? 1 : 0
  instance_id   = aws_instance.foundation.id
  allocation_id = aws_eip.foundation[0].id
}
```

Continue with `variables.tf` and `outputs.tf`...

## Phase 3: Ansible Roles

### Step 3.1: Foundation UI Role

```bash
cd ansible/roles/foundation-ui
```

Create `defaults/main.yml`:

```yaml
---
# Git repositories
calldata_platform_repo: "https://github.com/YOUR-ORG/calldata-platform.git"
calldata_platform_version: "main"
foundation_plugins_repo: "https://github.com/YOUR-ORG/foundation-ui-plugins.git"
foundation_plugins_version: "main"

# Installation paths
wazo_ui_path: "/usr/lib/python3/dist-packages/wazo_ui"
custom_ui_build_path: "/tmp/calldata-platform"
plugins_build_path: "/tmp/foundation-ui-plugins"

# Feature flags
enable_custom_theme: true
enable_analytics_plugin: true
enable_reporting_plugin: false
enable_dashboard_plugin: false

# Database connection
database_host: "localhost"
database_port: 5432
database_name: "asterisk"
database_user: "asterisk"
database_password: ""  # Set via vault or environment

# RabbitMQ connection
rabbitmq_host: "localhost"
rabbitmq_port: 5672
rabbitmq_user: "guest"
rabbitmq_password: ""  # Set via vault or environment
```

Create `tasks/main.yml`:

```yaml
---
- name: Install build dependencies
  apt:
    name:
      - git
      - python3-pip
      - python3-setuptools
      - python3-wheel
      - build-essential
      - nginx
    state: present
    update_cache: yes

- name: Clone calldata-platform repository
  git:
    repo: "{{ calldata_platform_repo }}"
    dest: "{{ custom_ui_build_path }}"
    version: "{{ calldata_platform_version }}"
    force: yes
  register: platform_clone

- name: Clone foundation-ui-plugins repository
  git:
    repo: "{{ foundation_plugins_repo }}"
    dest: "{{ plugins_build_path }}"
    version: "{{ foundation_plugins_version }}"
    force: yes
  register: plugins_clone

- name: Install Wazo UI platform package
  apt:
    name: wazo-ui
    state: present

- name: Deploy custom UI customizations
  import_tasks: install_custom_ui.yml
  when: platform_clone.changed or enable_custom_theme

- name: Install plugins
  import_tasks: install_plugins.yml
  when: plugins_clone.changed

- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/sites-available/foundation-ui
  notify: restart nginx

- name: Enable nginx site
  file:
    src: /etc/nginx/sites-available/foundation-ui
    dest: /etc/nginx/sites-enabled/foundation-ui
    state: link
  notify: restart nginx

- name: Restart Wazo UI service
  systemd:
    name: wazo-ui
    state: restarted
    enabled: yes
```

## Phase 4: GitHub Actions Workflows

(Due to length, this would be a separate detailed section)

## Summary

This implementation guide provides the foundation for building the calldata-foundation repository. Key points:

1. **Repository Structure**: Organized like aws-saas-ui but purpose-built for CallData
2. **Terraform Modules**: Modular, reusable infrastructure components
3. **Ansible Roles**: Configuration management for each service
4. **GitHub Actions**: Automated CI/CD pipelines
5. **Git Submodules**: Integration with calldata-platform and foundation-ui-plugins

## Next Steps

1. Complete all Terraform modules
2. Complete all Ansible roles
3. Create GitHub Actions workflows
4. Write comprehensive tests
5. Deploy to dev environment
6. Iterate and refine

---

**Document Version**: 1.0
**Last Updated**: 2025-11-01
**Author**: CallData Platform Team
