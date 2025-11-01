# CallData Foundation - Implementation Roadmap

## Project Goal
Automated deployment of Wazo Platform infrastructure to AWS with CI/CD pipeline that provisions infrastructure (Terraform) and configures services (Ansible) on git push.

---

## Phase 1: Infrastructure Foundation

### 1.1 AWS Setup & Prerequisites
- [ ] Create AWS account and configure billing alerts
- [ ] Set up AWS IAM user for Terraform with appropriate permissions
- [ ] Generate and securely store AWS access keys
- [ ] Create S3 bucket for Terraform state (with versioning enabled)
- [ ] Create DynamoDB table for Terraform state locking
- [ ] Set up AWS EC2 key pair for SSH access
- [ ] Configure AWS VPC and networking (or use defaults initially)

### 1.2 GitHub Repository Setup
- [ ] Initialize git repository in calldata-foundation
- [ ] Create GitHub repository (public or private)
- [ ] Add GitHub repository as remote origin
- [ ] Create `.gitignore` for Terraform/Ansible sensitive files
- [ ] Set up branch protection rules (main, stage, prod)

### 1.3 GitHub Secrets Configuration
Required secrets for GitHub Actions:
- [ ] `AWS_ACCESS_KEY_ID` - AWS access key
- [ ] `AWS_SECRET_ACCESS_KEY` - AWS secret key
- [ ] `AWS_REGION` - Target AWS region (e.g., us-east-1)
- [ ] `TF_STATE_BUCKET` - S3 bucket name for Terraform state
- [ ] `SSH_PRIVATE_KEY` - Private key for Ansible to SSH into instances
- [ ] `ANSIBLE_VAULT_PASSWORD` - Password for Ansible Vault encrypted vars

---

## Phase 2: Terraform Infrastructure Code

### 2.1 Terraform Modules
- [ ] **VPC Module** (`terraform/modules/vpc/`)
  - [ ] VPC with public/private subnets
  - [ ] Internet Gateway
  - [ ] NAT Gateway (for private subnets)
  - [ ] Route tables
  - [ ] Security groups

- [ ] **EC2 Module** (`terraform/modules/ec2/`)
  - [ ] EC2 instance resource
  - [ ] Elastic IP allocation
  - [ ] User data script support
  - [ ] Variables for instance type, AMI, key pair
  - [ ] Tags for environment identification

- [ ] **Network Module** (`terraform/modules/network/`)
  - [ ] Application Load Balancer (ALB)
  - [ ] Target groups
  - [ ] Route53 DNS records (optional)

- [ ] **RDS Module** (`terraform/modules/rds/`) (optional for PostgreSQL)
  - [ ] RDS PostgreSQL instance
  - [ ] Subnet group
  - [ ] Parameter group
  - [ ] Security group

### 2.2 Environment-Specific Configurations

#### Dev Environment (`terraform/environments/dev/`)
- [ ] `main.tf` - All-in-one Wazo server configuration
  - Single t3.xlarge instance
  - Public IP for easy access
  - Development security group (more permissive)
- [ ] `variables.tf` - Input variables
- [ ] `outputs.tf` - Export IPs, DNS names for Ansible
- [ ] `terraform.tfvars` - Dev-specific values
- [ ] `backend.tf` - S3 backend configuration
- [ ] `provider.tf` - AWS provider configuration

#### Stage Environment (`terraform/environments/stage/`)
- [ ] `main.tf` - Multi-node Wazo deployment
  - Separate UC Engine, C4 Router, C4 SBC instances
  - Private subnets with ALB
  - Stage security groups
- [ ] `variables.tf`
- [ ] `outputs.tf`
- [ ] `terraform.tfvars`
- [ ] `backend.tf`
- [ ] `provider.tf`

#### Prod Environment (`terraform/environments/prod/`)
- [ ] `main.tf` - Production HA configuration
  - Auto-scaling groups
  - Multi-AZ deployment
  - RDS Multi-AZ PostgreSQL
  - Production-grade security groups
- [ ] `variables.tf`
- [ ] `outputs.tf`
- [ ] `terraform.tfvars`
- [ ] `backend.tf`
- [ ] `provider.tf`

### 2.3 Terraform Helper Scripts
- [ ] `terraform/scripts/init.sh` - Initialize Terraform with backend
- [ ] `terraform/scripts/plan.sh` - Run terraform plan for environment
- [ ] `terraform/scripts/apply.sh` - Apply Terraform changes
- [ ] `terraform/scripts/destroy.sh` - Destroy infrastructure safely
- [ ] `terraform/scripts/output-to-inventory.sh` - Export outputs for Ansible

---

## Phase 3: Ansible Configuration Management

### 3.1 Ansible Project Structure
- [ ] `ansible/ansible.cfg` - Ansible configuration
  - SSH settings
  - Inventory path
  - Retry files disabled
  - Host key checking disabled for automation

- [ ] `ansible/requirements.yml` - External Ansible Galaxy roles
  - Wazo official roles (from wazo-ansible repository)
  - geerlingguy.postgresql
  - geerlingguy.security

### 3.2 Inventory Management
- [ ] `ansible/inventories/dev/hosts.yml` - Dynamic inventory from Terraform
- [ ] `ansible/inventories/dev/group_vars/all.yml` - Common variables
- [ ] `ansible/inventories/dev/group_vars/wazo.yml` - Wazo-specific vars
- [ ] Repeat for stage and prod environments
- [ ] `scripts/generate-inventory.py` - Python script to convert Terraform outputs to Ansible inventory

### 3.3 Ansible Playbooks
- [ ] `ansible/playbooks/site.yml` - Master playbook (runs all)
- [ ] `ansible/playbooks/common.yml` - Base system configuration
  - Update packages
  - Configure users
  - SSH hardening
  - Install monitoring agents
- [ ] `ansible/playbooks/uc-engine.yml` - Wazo UC Engine deployment
  - Use wazo-ansible roles
  - Configure PostgreSQL
  - Set up Asterisk
- [ ] `ansible/playbooks/c4-router.yml` - Wazo C4 Router setup
- [ ] `ansible/playbooks/c4-sbc.yml` - Wazo C4 SBC setup
- [ ] `ansible/playbooks/monitoring.yml` - Set up monitoring/logging
- [ ] `ansible/playbooks/backup.yml` - Configure backup jobs

### 3.4 Custom Ansible Roles
- [ ] `ansible/roles/common/` - Base OS configuration
  - tasks/main.yml
  - handlers/main.yml
  - defaults/main.yml

- [ ] `ansible/roles/security/` - Security hardening
  - Firewall (ufw/iptables)
  - Fail2ban
  - Automatic security updates

- [ ] `ansible/roles/monitoring/` - Monitoring setup
  - Install node_exporter (Prometheus)
  - Configure CloudWatch agent (AWS)
  - Set up logging aggregation

- [ ] `ansible/roles/backup/` - Backup configuration
  - Automated backup scripts
  - S3 backup uploads
  - Retention policies

### 3.5 Ansible Vault for Secrets
- [ ] Create encrypted vars file: `ansible/inventories/dev/group_vars/vault.yml`
  - Database passwords
  - API keys
  - SSL certificates
- [ ] Repeat for stage and prod
- [ ] Document vault password management in README

---

## Phase 4: CI/CD Pipeline (GitHub Actions)

### 4.1 Workflow for Dev Environment
**File**: `.github/workflows/deploy-dev.yml`

- [ ] Trigger: Push to `main` branch
- [ ] **Job 1: Terraform Plan**
  - Checkout code
  - Configure AWS credentials
  - Setup Terraform
  - Initialize Terraform (dev environment)
  - Run terraform plan
  - Post plan as PR comment (optional)

- [ ] **Job 2: Terraform Apply**
  - Depends on plan job
  - Run terraform apply -auto-approve
  - Export outputs to artifacts

- [ ] **Job 3: Wait for Instances**
  - Wait for EC2 instances to be ready (cloud-init complete)
  - Health check endpoint

- [ ] **Job 4: Ansible Configuration**
  - Install Ansible and dependencies
  - Download Terraform outputs
  - Generate Ansible inventory
  - Run ansible-playbook for site.yml
  - Use ansible-vault with GitHub secret for vault password

- [ ] **Job 5: Smoke Tests**
  - Verify Wazo services are running
  - Check API endpoints
  - Test SIP registration

### 4.2 Workflow for Stage Environment
**File**: `.github/workflows/deploy-stage.yml`

- [ ] Trigger: Push to `stage` branch
- [ ] Add manual approval gate before terraform apply
- [ ] Same jobs as dev workflow adapted for stage environment
- [ ] Additional integration tests

### 4.3 Workflow for Prod Environment
**File**: `.github/workflows/deploy-prod.yml`

- [ ] Trigger: Push to `prod` branch or manual workflow_dispatch
- [ ] Require manual approval from team
- [ ] Terraform plan only (no auto-apply)
- [ ] Separate workflow for apply after approval
- [ ] Blue-green deployment strategy
- [ ] Rollback capability

### 4.4 Additional Workflows
- [ ] `.github/workflows/terraform-lint.yml` - Run terraform validate and fmt
- [ ] `.github/workflows/ansible-lint.yml` - Run ansible-lint on playbooks
- [ ] `.github/workflows/destroy-dev.yml` - Manual workflow to destroy dev env
- [ ] `.github/workflows/security-scan.yml` - Scan for secrets/vulnerabilities

---

## Phase 5: Orchestration Scripts

### 5.1 Deployment Automation
- [ ] `scripts/deploy-environment.sh` - End-to-end deployment script
  ```bash
  Usage: ./scripts/deploy-environment.sh [dev|stage|prod]
  ```
  - Runs Terraform
  - Generates inventory
  - Runs Ansible
  - Performs health checks

- [ ] `scripts/generate-inventory.sh` - Convert TF outputs to Ansible inventory
- [ ] `scripts/tf-to-inventory.py` - Python helper for inventory generation
- [ ] `scripts/health-check.sh` - Verify all services are healthy
- [ ] `scripts/rollback.sh` - Rollback to previous Terraform state

### 5.2 Utility Scripts
- [ ] `scripts/ssh-to-host.sh` - Quick SSH to environment hosts
- [ ] `scripts/ansible-run.sh` - Wrapper for running ad-hoc Ansible commands
- [ ] `scripts/backup-now.sh` - Trigger immediate backup
- [ ] `scripts/show-logs.sh` - Tail logs from remote hosts

---

## Phase 6: Documentation

### 6.1 Core Documentation
- [ ] `README.md` - Project overview and quick start
  - What is CallData Foundation
  - Architecture diagram
  - Prerequisites
  - Quick start guide
  - Contributing guidelines

- [ ] `docs/architecture.md` - System architecture
  - Infrastructure diagram
  - Component descriptions
  - Network topology
  - Security architecture

- [ ] `docs/deployment.md` - Deployment procedures
  - Initial setup steps
  - Environment-specific deployments
  - Troubleshooting guide
  - Known issues

- [ ] `docs/runbook.md` - Operational runbook
  - Monitoring and alerts
  - Common tasks
  - Incident response
  - Backup and restore procedures

- [ ] `docs/development.md` - Development guide
  - Local testing with Vagrant/Docker
  - Testing changes before deployment
  - Code review process

- [ ] `docs/aws-setup.md` - AWS account setup guide
  - IAM policies
  - Required services
  - Cost estimation

- [ ] `docs/github-actions-setup.md` - CI/CD setup guide
  - Configuring secrets
  - Branch strategy
  - Approval workflows

### 6.2 Inline Documentation
- [ ] Add comments to all Terraform modules
- [ ] Document all Ansible role variables
- [ ] Add README.md in each major directory
- [ ] Create CHANGELOG.md for version tracking

---

## Phase 7: Testing & Validation

### 7.1 Local Testing
- [ ] Set up local testing with Terraform
  - Use `terraform console` for testing expressions
  - Test modules in isolation

- [ ] Set up Ansible testing
  - Use Molecule for role testing
  - Test playbooks with `--check` mode
  - Validate inventory generation

### 7.2 Integration Testing
- [ ] Create test suite for deployed infrastructure
  - Verify EC2 instances are accessible
  - Check security group rules
  - Validate Ansible configuration applied correctly

- [ ] Create smoke tests for Wazo services
  - UC Engine API responding
  - SIP server accepting registrations
  - Database connections working

### 7.3 Security Testing
- [ ] Run security scans on Terraform code
- [ ] Audit AWS security groups
- [ ] Test SSH access restrictions
- [ ] Verify secrets are not exposed in logs

---

## Phase 8: Production Readiness

### 8.1 Monitoring & Alerting
- [ ] Set up CloudWatch dashboards
- [ ] Configure CloudWatch alarms
  - CPU utilization
  - Memory usage
  - Disk space
  - Network traffic
- [ ] Set up SNS topics for alerts
- [ ] Configure PagerDuty/Slack integration

### 8.2 Logging
- [ ] Centralized logging with CloudWatch Logs
- [ ] Configure log retention policies
- [ ] Set up log analysis/search

### 8.3 Backup & Disaster Recovery
- [ ] Automated daily backups to S3
- [ ] Cross-region backup replication
- [ ] Document restore procedures
- [ ] Test disaster recovery plan

### 8.4 Security Hardening
- [ ] Enable AWS GuardDuty
- [ ] Configure AWS Security Hub
- [ ] Enable VPC Flow Logs
- [ ] Set up AWS Config for compliance
- [ ] Regular security patching strategy

### 8.5 Cost Optimization
- [ ] Tag all resources for cost tracking
- [ ] Set up AWS Cost Explorer
- [ ] Configure budget alerts
- [ ] Review instance sizes and optimize
- [ ] Use reserved instances for prod

---

## Phase 9: Post-Deployment Tasks

### 9.1 Initial Configuration
- [ ] Configure Wazo UC Engine via web UI
  - Create admin user
  - Configure SIP trunk
  - Set up users/extensions
  - Configure call routing

- [ ] Configure Wazo C4 Router
  - Set up routing tables
  - Configure carriers
  - Test call flow

### 9.2 Operational Procedures
- [ ] Document change management process
- [ ] Create on-call rotation schedule
- [ ] Set up regular maintenance windows
- [ ] Establish backup verification schedule

### 9.3 Training
- [ ] Train team on deployment process
- [ ] Train team on Wazo administration
- [ ] Document common operational tasks
- [ ] Create troubleshooting guides

---

## Quick Start Checklist (Priority Order)

### Immediate Actions (Week 1)
1. [ ] Set up AWS account and IAM user
2. [ ] Create GitHub repository
3. [ ] Initialize Terraform backend (S3 + DynamoDB)
4. [ ] Create basic VPC and EC2 Terraform modules
5. [ ] Create dev environment Terraform config
6. [ ] Test manual Terraform deployment to dev

### Short Term (Week 2)
7. [ ] Set up Ansible basic playbook for common config
8. [ ] Integrate Wazo ansible roles
9. [ ] Create inventory generation script
10. [ ] Test manual Ansible configuration on dev instance
11. [ ] Create deploy-environment.sh orchestration script

### Medium Term (Week 3-4)
12. [ ] Create GitHub Actions workflow for dev environment
13. [ ] Configure GitHub secrets
14. [ ] Test automated deployment (git push -> AWS)
15. [ ] Add smoke tests to CI/CD pipeline
16. [ ] Create stage environment
17. [ ] Document the entire process

### Long Term (Month 2+)
18. [ ] Create production environment with HA
19. [ ] Set up monitoring and alerting
20. [ ] Implement backup and disaster recovery
21. [ ] Security hardening and compliance
22. [ ] Cost optimization

---

## Success Criteria

The project is complete when:
- ✅ Pushing to `main` branch automatically deploys to dev environment
- ✅ Pushing to `stage` branch automatically deploys to stage environment
- ✅ Production deployment available via manual approval workflow
- ✅ All Wazo services are accessible and functional
- ✅ Monitoring and alerting are in place
- ✅ Backups are automated and tested
- ✅ Documentation is complete and accurate
- ✅ Team is trained on operations

---

## Notes & Considerations

### Technology Choices
- **Terraform**: Infrastructure provisioning (immutable infrastructure)
- **Ansible**: Configuration management (mutable configuration)
- **GitHub Actions**: CI/CD pipeline (alternative: GitLab CI, CircleCI)
- **AWS**: Cloud provider (could be adapted for GCP/Azure)

### Alternative Approaches
- Consider using Terraform Cloud for state management
- Consider using Ansible AWX/Tower for centralized automation
- Consider using Packer for pre-built AMIs with Wazo installed
- Consider using Docker/Kubernetes for containerized deployment

### Cost Estimates (Monthly)
- **Dev**: ~$50-100 (single t3.xlarge, networking)
- **Stage**: ~$200-300 (multiple instances, ALB)
- **Prod**: ~$500-1000+ (HA setup, RDS Multi-AZ, backups)

### Security Best Practices
- Never commit secrets to git
- Use Ansible Vault for sensitive data
- Rotate SSH keys regularly
- Enable MFA on AWS account
- Regular security audits
- Principle of least privilege for IAM

---

## Questions to Resolve

- [ ] Which AWS region to use? (Consider latency, compliance, costs)
- [ ] Domain name for Wazo services? (DNS configuration needed)
- [ ] SSL certificates - Use Let's Encrypt or AWS ACM?
- [ ] Backup retention period? (7 days, 30 days, 90 days?)
- [ ] Monitoring solution - CloudWatch only or add Prometheus/Grafana?
- [ ] Log aggregation - CloudWatch Logs or ELK stack?
- [ ] Do we need a bastion host for SSH access?
- [ ] What's the disaster recovery RTO/RPO requirements?
