# CallData Foundation Platform - Architecture Document

## Overview

The CallData Foundation Platform is a complete replacement deployment for Wazo Platform, designed with custom UI components and plugin extensibility. This is **NOT** an add-on to the existing all-in-one Wazo deployment - it is a standalone, purpose-built deployment system.

## Design Principles

### Lessons Learned from aws-saas-ui

1. **Modular Terraform Structure**: Separate modules for VPC, compute, and application-specific resources
2. **Environment Isolation**: Each environment (dev, staging, prod) has its own Terraform workspace
3. **IAM SSM-based Access**: No SSH keys, all access via AWS Systems Manager
4. **Ansible for Configuration**: Terraform provisions infrastructure, Ansible configures applications
5. **GitHub Actions CI/CD**: Automated deployment with manual approval gates
6. **Resource Cleanup**: Automated cleanup scripts for orphaned resources
7. **State Management**: S3 backend with DynamoDB locking

### New Requirements

1. **Custom UI Integration**: Deploy calldata-platform (Wazo UI fork) instead of vanilla Wazo UI
2. **Plugin System**: Automatically install and configure foundation-ui-plugins
3. **Microservices Architecture**: Separate components (auth, confd, calld, UI) into distinct services
4. **Container Support**: Option to deploy backend services in Docker containers
5. **Database Separation**: PostgreSQL in RDS instead of on-instance
6. **Message Bus Separation**: RabbitMQ in AmazonMQ or separate EC2
7. **High Availability**: Multi-AZ deployment support
8. **Monitoring**: Built-in CloudWatch, Prometheus, Grafana

## Repository Structure

```
calldata-foundation/
├── .github/
│   └── workflows/
│       ├── deploy-dev.yml                 # Deploy to dev environment
│       ├── deploy-staging.yml             # Deploy to staging environment
│       ├── deploy-prod.yml                # Deploy to production environment
│       └── destroy-dev.yml                # Destroy dev environment
│
├── terraform/
│   ├── modules/
│   │   ├── networking/
│   │   │   ├── main.tf                    # VPC, subnets, routing, NAT
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── database/
│   │   │   ├── main.tf                    # RDS PostgreSQL cluster
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── message-bus/
│   │   │   ├── main.tf                    # AmazonMQ or EC2 RabbitMQ
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── foundation-ui/
│   │   │   ├── main.tf                    # UI server (ECS or EC2)
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── foundation-auth/
│   │   │   ├── main.tf                    # wazo-auth service
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── foundation-confd/
│   │   │   ├── main.tf                    # wazo-confd service
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── foundation-calld/
│   │   │   ├── main.tf                    # wazo-calld service
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   └── foundation-asterisk/
│   │       ├── main.tf                    # Asterisk B2BUA
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   └── environments/
│       ├── dev/
│       │   ├── main.tf                    # Dev environment composition
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── providers.tf
│       │   ├── backend.tf                 # S3 + DynamoDB state
│       │   └── terraform.tfvars.example
│       │
│       ├── staging/
│       │   └── ... (same structure)
│       │
│       └── prod/
│           └── ... (same structure)
│
├── ansible/
│   ├── inventories/
│   │   ├── dev/
│   │   │   ├── hosts                     # Dynamic from Terraform outputs
│   │   │   └── group_vars/
│   │   │       ├── all.yml
│   │   │       └── vault.yml.example
│   │   │
│   │   ├── staging/
│   │   └── prod/
│   │
│   ├── roles/
│   │   ├── foundation-ui/
│   │   │   ├── tasks/
│   │   │   │   ├── main.yml
│   │   │   │   ├── install_custom_ui.yml
│   │   │   │   ├── install_plugins.yml
│   │   │   │   └── configure.yml
│   │   │   ├── templates/
│   │   │   ├── files/
│   │   │   ├── defaults/
│   │   │   │   └── main.yml
│   │   │   └── handlers/
│   │   │       └── main.yml
│   │   │
│   │   ├── foundation-auth/
│   │   ├── foundation-confd/
│   │   ├── foundation-calld/
│   │   ├── foundation-asterisk/
│   │   ├── foundation-database/
│   │   └── foundation-monitoring/
│   │
│   └── playbooks/
│       ├── deploy-all.yml                # Deploy entire platform
│       ├── deploy-ui.yml                 # Deploy UI only
│       ├── deploy-backend.yml            # Deploy backend services
│       └── update-plugins.yml            # Update plugins only
│
├── docker/
│   ├── foundation-ui/
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   │
│   ├── foundation-auth/
│   ├── foundation-confd/
│   ├── foundation-calld/
│   └── docker-compose.yml               # Local development
│
├── scripts/
│   ├── cleanup-orphaned-resources.sh    # Clean up AWS resources
│   ├── generate-inventory.sh            # Generate Ansible inventory from TF
│   ├── setup-secrets.sh                 # Configure GitHub secrets
│   └── validate-deployment.sh           # Post-deployment validation
│
├── docs/
│   ├── ARCHITECTURE.md                  # This file
│   ├── DEPLOYMENT.md                    # Deployment procedures
│   ├── DEVELOPMENT.md                   # Developer guide
│   ├── TROUBLESHOOTING.md              # Common issues
│   └── API.md                          # API documentation
│
├── .gitmodules                          # Git submodules
├── README.md                            # Repository overview
└── LICENSE

## External Repository Dependencies

### Git Submodules

1. **calldata-platform** (wazo-ui fork)
   - Location: `platform-ui/`
   - Source: https://github.com/YOUR-ORG/calldata-platform.git
   - Purpose: Custom branded Wazo UI

2. **foundation-ui-plugins**
   - Location: `platform-plugins/`
   - Source: https://github.com/YOUR-ORG/foundation-ui-plugins.git
   - Purpose: Custom plugins (analytics, reporting, dashboard)

3. **wazo-ansible** (optional reference)
   - Location: `reference/wazo-ansible/`
   - Source: https://github.com/wazo-platform/wazo-ansible.git
   - Purpose: Reference for Wazo deployment patterns
```

## Deployment Architecture

### Option 1: All-in-One (Development)

All components run on a single EC2 instance:
- Asterisk (B2BUA)
- PostgreSQL (local)
- RabbitMQ (local)
- wazo-auth
- wazo-confd
- wazo-calld
- Custom UI + Plugins
- nginx (reverse proxy)

**Use Case**: Development, testing, proof-of-concept

### Option 2: Separated Services (Staging)

Components distributed across services:
- EC2: Asterisk + wazo-calld (telephony)
- RDS: PostgreSQL (database)
- AmazonMQ: RabbitMQ (message bus)
- ECS/EC2: wazo-auth (authentication)
- ECS/EC2: wazo-confd (configuration API)
- ECS/EC2: Custom UI + Plugins (web interface)
- ALB: Load balancer

**Use Case**: Staging environment, performance testing

### Option 3: Microservices + HA (Production)

Fully distributed with high availability:
- ASG: Asterisk cluster (multiple AZs)
- RDS Multi-AZ: PostgreSQL cluster
- AmazonMQ Multi-AZ: RabbitMQ cluster
- ECS Fargate: wazo-auth (multi-AZ, auto-scaling)
- ECS Fargate: wazo-confd (multi-AZ, auto-scaling)
- ECS Fargate: wazo-calld (multi-AZ, auto-scaling)
- ECS Fargate: Custom UI (multi-AZ, auto-scaling)
- ALB: Multi-AZ load balancer
- CloudFront: CDN for static assets
- Route53: DNS failover

**Use Case**: Production environment

## Infrastructure Components

### Networking Module

**Responsibilities**:
- Create VPC with public and private subnets across 3 AZs
- Internet Gateway for public subnets
- NAT Gateways for private subnets (one per AZ for HA)
- Route tables and associations
- Network ACLs
- VPC Flow Logs to CloudWatch

**Outputs**:
- VPC ID
- Public subnet IDs
- Private subnet IDs
- NAT Gateway IPs
- Security group IDs

### Database Module

**Responsibilities**:
- RDS PostgreSQL cluster (Multi-AZ)
- Parameter group (optimized for Wazo)
- Subnet group
- Security groups
- Automated backups (30-day retention)
- Encryption at rest (KMS)
- Enhanced monitoring

**Outputs**:
- Database endpoint
- Database port
- Database name
- Credentials secret ARN (Secrets Manager)

### Message Bus Module

**Two Options**:

**Option A: AmazonMQ (Managed RabbitMQ)**
- Broker configuration
- Security groups
- Access credentials in Secrets Manager

**Option B: Self-managed RabbitMQ on EC2**
- EC2 instance with Docker
- Persistent EBS volume
- Security groups
- Automated backups

**Outputs**:
- RabbitMQ endpoint
- Admin credentials secret ARN

### Foundation UI Module

**Responsibilities**:
- EC2 instance or ECS service for UI
- IAM role for SSM access
- Security groups (HTTP/HTTPS)
- Install calldata-platform (custom UI)
- Install foundation-ui-plugins
- Configure nginx reverse proxy
- SSL/TLS certificates (ACM or Let's Encrypt)

**Outputs**:
- UI endpoint (ALB DNS or EC2 public IP)
- UI service ARN (if ECS)

### Foundation Auth Module

**Responsibilities**:
- wazo-auth service deployment
- Database connection configuration
- RabbitMQ connection configuration
- JWT secret management (Secrets Manager)
- Security groups

**Outputs**:
- Auth service endpoint
- Health check URL

### Foundation Confd Module

**Responsibilities**:
- wazo-confd service deployment
- Database connection configuration
- RabbitMQ connection configuration
- API authentication configuration
- Security groups

**Outputs**:
- Confd service endpoint
- Health check URL

### Foundation Calld Module

**Responsibilities**:
- wazo-calld service deployment
- Asterisk connection configuration
- RabbitMQ connection configuration
- WebRTC gateway configuration
- Security groups

**Outputs**:
- Calld service endpoint
- Health check URL

### Foundation Asterisk Module

**Responsibilities**:
- Asterisk B2BUA deployment
- SIP/RTP port configuration
- Security groups (SIP, RTP, IAX)
- Codec configuration
- Dialplan configuration
- Trunk configuration

**Outputs**:
- Asterisk manager interface endpoint
- SIP endpoint

## Ansible Configuration Management

### Foundation UI Role

**Tasks**:
1. Clone calldata-platform repository
2. Install Python dependencies
3. Deploy custom branding files
4. Deploy custom theme CSS
5. Clone foundation-ui-plugins repository
6. Install each plugin via pip
7. Configure plugin loading
8. Configure nginx
9. Setup systemd service
10. Restart services

**Variables**:
```yaml
calldata_platform_repo: "https://github.com/YOUR-ORG/calldata-platform.git"
calldata_platform_version: "main"
foundation_plugins_repo: "https://github.com/YOUR-ORG/foundation-ui-plugins.git"
foundation_plugins_version: "main"
enable_analytics_plugin: true
enable_reporting_plugin: true
enable_dashboard_plugin: true
database_host: "{{ hostvars['database'].endpoint }}"
rabbitmq_host: "{{ hostvars['messagebus'].endpoint }}"
```

### Foundation Auth Role

**Tasks**:
1. Install wazo-auth package or Docker image
2. Configure database connection
3. Configure RabbitMQ connection
4. Setup JWT keys
5. Configure authentication backends (LDAP, SAML, OAuth)
6. Setup systemd service or Docker container
7. Initialize database schema
8. Create default tenants and users

### Foundation Confd Role

**Tasks**:
1. Install wazo-confd package or Docker image
2. Configure database connection
3. Configure RabbitMQ connection
4. Setup API authentication
5. Configure CORS settings
6. Setup systemd service or Docker container
7. Initialize configuration database

### Foundation Calld Role

**Tasks**:
1. Install wazo-calld package or Docker image
2. Configure Asterisk connection (AMI)
3. Configure RabbitMQ connection
4. Configure WebRTC settings
5. Setup systemd service or Docker container

### Foundation Asterisk Role

**Tasks**:
1. Install Asterisk package
2. Configure SIP trunks
3. Configure dialplan
4. Configure codecs
5. Configure AMI (Asterisk Manager Interface)
6. Configure CDR (Call Detail Records)
7. Setup systemd service

## GitHub Actions Workflows

### Deploy Dev Workflow

**Trigger**: Push to `main` branch or manual dispatch

**Jobs**:
1. **Terraform Plan**
   - Checkout code
   - Initialize submodules (calldata-platform, foundation-ui-plugins)
   - Configure AWS credentials
   - Run Terraform plan
   - Upload plan artifact

2. **Terraform Apply**
   - Download plan artifact
   - Apply Terraform
   - Output infrastructure details

3. **Ansible Deploy**
   - Generate inventory from Terraform outputs
   - Run Ansible playbooks via SSM
   - Deploy custom UI
   - Install plugins
   - Configure all services

4. **Validation**
   - Run health checks on all services
   - Test UI accessibility
   - Test plugin functionality
   - Run integration tests

5. **Notification**
   - Send deployment summary to Slack/Teams
   - Update deployment dashboard

### Destroy Dev Workflow

**Trigger**: Manual dispatch with confirmation

**Jobs**:
1. **Confirmation Check**
   - Require typed confirmation
2. **Terraform Destroy**
   - Destroy all resources
   - Clean up orphaned resources
3. **Notification**
   - Send destruction summary

## Security Considerations

1. **Secrets Management**:
   - All secrets in AWS Secrets Manager
   - No hardcoded credentials
   - Automatic secret rotation

2. **Network Security**:
   - Private subnets for backend services
   - Security groups with least privilege
   - WAF for public endpoints

3. **Encryption**:
   - EBS volumes encrypted (KMS)
   - RDS encrypted at rest
   - TLS/SSL for all communications
   - Secrets Manager encryption

4. **Access Control**:
   - IAM roles with least privilege
   - SSM Session Manager (no SSH keys)
   - MFA for production deployments
   - Audit logs to CloudTrail

5. **Compliance**:
   - HIPAA-eligible architecture (if needed)
   - PCI DSS considerations
   - SOC 2 compliance support

## Monitoring and Observability

1. **Metrics**:
   - CloudWatch metrics for all services
   - Custom metrics for telephony (call volume, quality)
   - Prometheus exporters for detailed metrics

2. **Logging**:
   - CloudWatch Logs for all services
   - Centralized log aggregation
   - Log retention policies
   - Log analysis with CloudWatch Insights

3. **Tracing**:
   - AWS X-Ray for distributed tracing
   - Request flow visualization
   - Performance bottleneck identification

4. **Alerting**:
   - CloudWatch Alarms for critical metrics
   - SNS notifications
   - PagerDuty integration
   - Slack/Teams integration

5. **Dashboards**:
   - CloudWatch Dashboards
   - Grafana dashboards
   - Custom UI analytics dashboard (plugin)

## Cost Optimization

1. **Resource Right-Sizing**:
   - Use appropriate instance types
   - Reserved Instances for production
   - Spot Instances for non-critical workloads

2. **Auto-Scaling**:
   - Scale based on metrics
   - Schedule-based scaling (business hours)
   - Predictive scaling

3. **Storage Optimization**:
   - S3 lifecycle policies
   - EBS snapshot lifecycle
   - Database storage auto-scaling

4. **Network Optimization**:
   - VPC endpoints for AWS services (no NAT costs)
   - CloudFront for static content
   - Direct Connect for high-volume

## Disaster Recovery

1. **Backup Strategy**:
   - Automated RDS snapshots (daily)
   - EBS snapshots (daily)
   - Configuration backups to S3
   - 30-day retention

2. **Recovery Procedures**:
   - RTO: 4 hours (staging), 1 hour (production)
   - RPO: 24 hours (staging), 1 hour (production)
   - Automated recovery scripts
   - Regular DR testing

3. **Multi-Region**:
   - Cross-region RDS read replicas
   - S3 cross-region replication
   - Route53 health checks and failover

## Comparison with aws-saas-ui

| Aspect | aws-saas-ui (Wazo) | calldata-foundation |
|--------|-------------------|---------------------|
| **Deployment** | All-in-one EC2 | Microservices option |
| **UI** | Vanilla Wazo UI | Custom calldata-platform |
| **Plugins** | None | foundation-ui-plugins |
| **Database** | On-instance PostgreSQL | RDS (optional) |
| **Message Bus** | On-instance RabbitMQ | AmazonMQ (optional) |
| **Infrastructure** | Shared VPC with LiteLLM | Dedicated VPC |
| **Configuration** | wazo-ansible submodule | Custom Ansible roles |
| **State** | S3 backend | S3 backend |
| **Access** | AWS SSM | AWS SSM |
| **Monitoring** | Basic CloudWatch | Full observability stack |
| **HA** | Single instance | Multi-AZ support |

## Migration Path from aws-saas-ui

1. **Phase 1**: Deploy calldata-foundation in dev (all-in-one)
2. **Phase 2**: Migrate custom UI and plugins
3. **Phase 3**: Test thoroughly
4. **Phase 4**: Deploy calldata-foundation in staging (microservices)
5. **Phase 5**: Performance and load testing
6. **Phase 6**: Deploy calldata-foundation in production
7. **Phase 7**: Cutover from aws-saas-ui to calldata-foundation
8. **Phase 8**: Decommission aws-saas-ui Wazo deployment

## Next Steps

1. **Create Repository Structure** - Initialize Git repository with directory structure
2. **Develop Terraform Modules** - Build networking, database, and compute modules
3. **Develop Ansible Roles** - Create roles for each component
4. **Create Docker Images** - Build containers for microservices deployment
5. **Setup CI/CD** - Configure GitHub Actions workflows
6. **Documentation** - Complete deployment and development guides
7. **Testing** - Develop integration and end-to-end tests
8. **Deploy Dev Environment** - First deployment to validate architecture

---

**Document Version**: 1.0
**Last Updated**: 2025-11-01
**Author**: CallData Platform Team
