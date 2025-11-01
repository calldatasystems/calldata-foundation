# CallData Foundation

> Automated Infrastructure-as-Code and Configuration Management for Wazo Platform on AWS

## Overview

CallData Foundation is an automated deployment solution for [Wazo Platform](https://wazo-platform.org/) - an open-source unified communications and VoIP platform. This project uses Terraform for infrastructure provisioning and Ansible for configuration management, with full CI/CD integration via GitHub Actions.

**Key Features:**
- 🚀 Automated deployment to AWS on git push
- 🔄 Multi-environment support (dev, stage, prod)
- 🏗️ Infrastructure as Code with Terraform
- ⚙️ Configuration Management with Ansible
- 🔒 Secure secrets management with Ansible Vault
- 📊 Integrated monitoring and logging
- 🔐 Security hardening and compliance
- 💾 Automated backups and disaster recovery

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│                  calldata-foundation                         │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ git push
                 ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions CI/CD Pipeline                   │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │  Terraform   │──▶│  Wait for    │──▶│    Ansible      │   │
│  │  Apply       │  │  Instances   │  │  Configuration  │   │
│  └──────────────┘  └──────────────┘  └─────────────────┘   │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ Provisions & Configures
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    VPC                                │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐    │   │
│  │  │  Wazo UC   │  │  Wazo C4   │  │  Wazo C4   │    │   │
│  │  │  Engine    │  │  Router    │  │  SBC       │    │   │
│  │  │  (PBX)     │  │            │  │            │    │   │
│  │  └────────────┘  └────────────┘  └────────────┘    │   │
│  │                                                      │   │
│  │  ┌────────────────────────────────────────────┐    │   │
│  │  │      RDS PostgreSQL (Multi-AZ)             │    │   │
│  │  └────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
calldata-foundation/
├── terraform/                  # Infrastructure as Code
│   ├── modules/               # Reusable Terraform modules
│   │   ├── vpc/              # VPC, subnets, security groups
│   │   ├── ec2/              # EC2 instances
│   │   ├── rds/              # RDS PostgreSQL
│   │   └── network/          # Load balancers, DNS
│   ├── environments/         # Environment-specific configs
│   │   ├── dev/              # Development (all-in-one)
│   │   ├── stage/            # Staging (multi-node)
│   │   └── prod/             # Production (HA)
│   └── scripts/              # Helper scripts
│
├── ansible/                   # Configuration Management
│   ├── inventories/          # Dynamic inventories per environment
│   ├── playbooks/            # Ansible playbooks
│   ├── roles/                # Custom Ansible roles
│   └── requirements.yml      # External roles (Wazo)
│
├── scripts/                   # Orchestration scripts
│   ├── deploy-environment.sh # End-to-end deployment
│   └── generate-inventory.sh # TF outputs to Ansible inventory
│
├── .github/                   # GitHub Actions workflows
│   └── workflows/
│       ├── deploy-dev.yml    # Auto-deploy to dev
│       ├── deploy-stage.yml  # Auto-deploy to stage
│       └── deploy-prod.yml   # Manual deploy to prod
│
├── docs/                      # Documentation
├── TODO.md                    # Implementation roadmap
└── README.md                  # This file
```

## Prerequisites

### Required Tools
- **Terraform** >= 1.5.0
- **Ansible** >= 2.15.0
- **Python** >= 3.9
- **AWS CLI** >= 2.0
- **Git**

### Required Accounts & Access
- **AWS Account** with administrative access
- **GitHub Account** for version control and CI/CD
- **Domain Name** (optional, for production)

### AWS Resources (to be created)
- S3 bucket for Terraform state
- DynamoDB table for Terraform state locking
- IAM user with programmatic access for Terraform
- EC2 key pair for SSH access

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/calldata-foundation.git
cd calldata-foundation
```

### 2. Set Up AWS Backend for Terraform
```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://calldata-tfstate-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -c1-8) --region us-east-1

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name calldata-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### 3. Configure Environment Variables
```bash
# Copy example terraform.tfvars
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars

# Edit with your AWS settings
nano terraform/environments/dev/terraform.tfvars
```

### 4. Deploy Development Environment
```bash
# Option A: Manual deployment
./scripts/deploy-environment.sh dev

# Option B: Push to GitHub for automated deployment
git add .
git commit -m "Initial deployment"
git push origin main
```

## Environment Configuration

### Development Environment
- **Purpose**: Testing and development
- **Architecture**: Single all-in-one server
- **Instance**: t3.xlarge (4 vCPU, 16 GB RAM)
- **Deployment**: Automatic on push to `main` branch
- **Cost**: ~$100/month

### Stage Environment
- **Purpose**: Pre-production testing
- **Architecture**: Multi-node (separate UC Engine, C4 Router, C4 SBC)
- **Instances**: Multiple t3.large instances
- **Deployment**: Automatic on push to `stage` branch
- **Cost**: ~$300/month

### Production Environment
- **Purpose**: Live production traffic
- **Architecture**: High availability, multi-AZ
- **Instances**: Auto-scaling groups, load balanced
- **Database**: RDS Multi-AZ PostgreSQL
- **Deployment**: Manual approval required
- **Cost**: ~$800-1500/month

## CI/CD Pipeline

The project uses GitHub Actions for automated deployments:

### Workflow Triggers
- **Dev**: Auto-deploys on push to `main` branch
- **Stage**: Auto-deploys on push to `stage` branch
- **Prod**: Manual trigger with approval required

### Deployment Steps
1. **Terraform Plan** - Preview infrastructure changes
2. **Terraform Apply** - Provision AWS resources
3. **Wait for Instances** - Ensure EC2 instances are ready
4. **Ansible Configuration** - Configure Wazo services
5. **Smoke Tests** - Verify deployment success

### Required GitHub Secrets
Configure these in GitHub repository settings:
```
AWS_ACCESS_KEY_ID          # AWS access key
AWS_SECRET_ACCESS_KEY      # AWS secret key
AWS_REGION                 # AWS region (e.g., us-east-1)
TF_STATE_BUCKET            # S3 bucket for Terraform state
SSH_PRIVATE_KEY            # Private key for Ansible SSH
ANSIBLE_VAULT_PASSWORD     # Ansible Vault password
```

## Manual Deployment

### Deploy to Environment
```bash
# Deploy to dev
./scripts/deploy-environment.sh dev

# Deploy to stage
./scripts/deploy-environment.sh stage

# Deploy to prod (with confirmation)
./scripts/deploy-environment.sh prod
```

### Terraform Only
```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Ansible Only
```bash
cd ansible
ansible-playbook -i inventories/dev/hosts.yml playbooks/site.yml
```

## Configuration

### Terraform Variables
Edit `terraform/environments/[env]/terraform.tfvars`:
```hcl
# AWS Configuration
aws_region        = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]

# Instance Configuration
instance_type     = "t3.xlarge"
key_name          = "your-ec2-key-name"

# Network Configuration
vpc_cidr          = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# Tags
environment       = "dev"
project           = "calldata-foundation"
```

### Ansible Variables
Edit `ansible/inventories/[env]/group_vars/all.yml`:
```yaml
# Wazo Configuration
wazo_distribution: "wazo-dev"  # or "wazo-rc" for stable
wazo_engine_version: "latest"

# Database Configuration
postgresql_version: "15"
database_name: "asterisk"

# Security
ssh_port: 22
enable_firewall: true
```

### Secrets Management
Encrypt sensitive data with Ansible Vault:
```bash
# Create encrypted vars file
ansible-vault create ansible/inventories/dev/group_vars/vault.yml

# Edit encrypted file
ansible-vault edit ansible/inventories/dev/group_vars/vault.yml

# Variables to encrypt:
# - database_password
# - api_keys
# - ssl_certificate_key
```

## Accessing Deployed Infrastructure

### SSH Access
```bash
# SSH to dev environment
./scripts/ssh-to-host.sh dev uc-engine

# SSH to specific host
ssh -i ~/.ssh/calldata-key.pem admin@<instance-ip>
```

### Wazo Web UI
- **URL**: `https://<instance-ip>` or `https://wazo.yourdomain.com`
- **Default Admin**: Set during initial configuration
- **Port**: 443 (HTTPS)

### Wazo API
- **URL**: `https://<instance-ip>/api/`
- **Documentation**: https://wazo-platform.org/documentation
- **Port**: 443 (HTTPS)

## Monitoring & Logging

### CloudWatch Dashboards
View metrics in AWS Console:
- CPU, Memory, Disk usage
- Network traffic
- Wazo-specific metrics

### CloudWatch Logs
- System logs: `/var/log/syslog`
- Wazo logs: `/var/log/wazo-*`
- Asterisk logs: `/var/log/asterisk/`

### Alerts
Configure in `terraform/environments/[env]/main.tf`:
- High CPU utilization
- Low disk space
- Service health checks
- Failed authentication attempts

## Backup & Disaster Recovery

### Automated Backups
- **Frequency**: Daily at 02:00 UTC
- **Retention**: 7 days for dev, 30 days for prod
- **Storage**: S3 with versioning enabled
- **Contents**:
  - PostgreSQL database dumps
  - Wazo configuration files
  - Call recording files

### Manual Backup
```bash
# Trigger immediate backup
./scripts/backup-now.sh dev
```

### Restore from Backup
```bash
# List available backups
aws s3 ls s3://calldata-backups-dev/

# Restore specific backup
./scripts/restore-backup.sh dev 2024-01-15
```

## Troubleshooting

### Common Issues

#### Terraform State Lock
```bash
# If terraform is stuck due to state lock
terraform force-unlock <LOCK_ID>
```

#### Ansible Connection Timeout
```bash
# Verify SSH connectivity
ansible all -i inventories/dev/hosts.yml -m ping

# Check security groups allow SSH from your IP
aws ec2 describe-security-groups --group-ids <sg-id>
```

#### Wazo Services Not Starting
```bash
# SSH to instance and check service status
sudo wazo-service status

# Check logs
sudo tail -f /var/log/wazo-*/wazo-*.log
```

### Getting Help
- Check logs in CloudWatch Logs
- Review `docs/runbook.md` for operational procedures
- Consult Wazo Platform documentation: https://wazo-platform.org
- Open an issue in this repository

## Security Considerations

### Best Practices
- ✅ All secrets stored in Ansible Vault or AWS Secrets Manager
- ✅ SSH key-based authentication only (no passwords)
- ✅ Security groups follow least-privilege principle
- ✅ Regular security patching via automated updates
- ✅ VPC Flow Logs enabled for network monitoring
- ✅ AWS GuardDuty for threat detection
- ✅ MFA enabled on AWS root account

### Security Hardening
The Ansible `security` role implements:
- Firewall configuration (ufw/iptables)
- Fail2ban for brute-force protection
- Automatic security updates
- SSH hardening
- Audit logging

## Cost Estimation

### Monthly Costs (Approximate)

| Environment | Compute | Storage | Networking | Total     |
|-------------|---------|---------|------------|-----------|
| Dev         | $70     | $10     | $20        | ~$100     |
| Stage       | $200    | $30     | $70        | ~$300     |
| Prod        | $600    | $100    | $200       | ~$900     |

**Cost optimization tips:**
- Use reserved instances for production (40-60% savings)
- Enable S3 lifecycle policies for backups
- Use Spot instances for non-critical dev environments
- Tag all resources for cost tracking

## Contributing

### Development Workflow
1. Create feature branch from `main`
2. Make changes and test locally
3. Run linters: `terraform fmt` and `ansible-lint`
4. Submit pull request
5. Automated tests run on PR
6. Merge after approval

### Testing Changes
```bash
# Validate Terraform
cd terraform/environments/dev
terraform validate
terraform fmt -check

# Check Ansible syntax
cd ansible
ansible-playbook --syntax-check playbooks/site.yml
ansible-lint playbooks/
```

## Roadmap

See [TODO.md](./TODO.md) for detailed implementation roadmap.

### Completed
- ✅ Project structure and documentation
- ⬜ Terraform modules for AWS infrastructure
- ⬜ Ansible playbooks for Wazo configuration
- ⬜ GitHub Actions CI/CD pipelines

### In Progress
- Development environment deployment
- Integration with Wazo official Ansible roles

### Planned
- Stage and production environments
- HA configuration and auto-scaling
- Monitoring and alerting setup
- Disaster recovery testing
- Cost optimization

## License

[Choose appropriate license - MIT, Apache 2.0, etc.]

## Maintainers

- Your Name (@github-username)

## Acknowledgments

- [Wazo Platform](https://wazo-platform.org/) - Open-source unified communications
- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- [Ansible](https://www.ansible.com/) - Configuration Management
- [AWS](https://aws.amazon.com/) - Cloud Infrastructure

## Links

- **Wazo Documentation**: https://wazo-platform.org/documentation
- **Wazo GitHub**: https://github.com/wazo-platform
- **Wazo Community**: https://wazo-platform.org/community
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Ansible Documentation**: https://docs.ansible.com/
