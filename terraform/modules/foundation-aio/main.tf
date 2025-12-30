# Foundation Platform All-in-One Module
# Creates a single EC2 instance with all components for dev environment

# Data source to get latest Debian 12 (Bookworm) AMI
data "aws_ami" "debian_bookworm" {
  most_recent = true
  owners      = ["136693071363"] # Official Debian AWS account

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Foundation Platform
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

  # SIP TLS
  ingress {
    description = "SIP TLS"
    from_port   = 5061
    to_port     = 5061
    protocol    = "tcp"
    cidr_blocks = var.sip_allowed_cidrs
  }

  # RTP (media)
  ingress {
    description = "RTP"
    from_port   = 10000
    to_port     = 20000
    protocol    = "udp"
    cidr_blocks = var.rtp_allowed_cidrs
  }

  # Egress - allow all
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-foundation-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for SSM Access
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

  tags = {
    Name        = "${var.project_name}-${var.environment}-foundation-ssm-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach AWS managed SSM policy
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.foundation_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for the EC2 instance
resource "aws_iam_instance_profile" "foundation" {
  name = "${var.project_name}-${var.environment}-foundation-profile"
  role = aws_iam_role.foundation_ssm.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-foundation-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}

# S3 bucket for SSM session logs (required by Ansible SSM plugin)
resource "aws_s3_bucket" "ssm_logs" {
  bucket = "${var.project_name}-${var.environment}-ssm-logs"

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssm-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Enable versioning on SSM logs bucket
resource "aws_s3_bucket_versioning" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to SSM logs bucket
resource "aws_s3_bucket_public_access_block" "ssm_logs" {
  bucket = aws_s3_bucket.ssm_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add S3 permissions to SSM role
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

# Foundation Platform Server Instance
resource "aws_instance" "foundation" {
  ami                    = var.use_custom_ami ? var.custom_ami_id : data.aws_ami.debian_bookworm.id
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

  # User data to prepare Debian Bookworm for Foundation Platform installation
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Disable automatic updates permanently FIRST
              echo 'APT::Periodic::Update-Package-Lists "0";' > /etc/apt/apt.conf.d/20auto-upgrades
              echo 'APT::Periodic::Unattended-Upgrade "0";' >> /etc/apt/apt.conf.d/20auto-upgrades

              # Disable automatic update services
              systemctl stop unattended-upgrades.service || true
              systemctl disable unattended-upgrades.service || true
              systemctl mask unattended-upgrades.service || true
              systemctl stop apt-daily.timer || true
              systemctl disable apt-daily.timer || true
              systemctl stop apt-daily-upgrade.timer || true
              systemctl disable apt-daily-upgrade.timer || true

              # Wait for any initial apt locks with timeout
              WAIT_COUNT=0
              while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
                if [ $WAIT_COUNT -gt 60 ]; then
                  break
                fi
                sleep 5
                WAIT_COUNT=$((WAIT_COUNT + 1))
              done

              # Install SSM agent (Debian 12 has Python3 pre-installed)
              cd /tmp
              curl -o amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
              dpkg -i amazon-ssm-agent.deb || true
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent

              # Ensure admin user exists with proper sudo access
              if ! id -u admin > /dev/null 2>&1; then
                useradd -m -s /bin/bash admin
              fi

              mkdir -p /home/admin/.ssh
              chmod 700 /home/admin/.ssh
              chown -R admin:admin /home/admin/.ssh

              # Add admin to sudoers
              echo "admin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/admin
              chmod 440 /etc/sudoers.d/admin

              # Signal completion
              touch /var/lib/cloud/instance/boot-finished
              EOF

  user_data_replace_on_change = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-foundation"
    Component   = "foundation-platform"
    Role        = "all-in-one"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm_policy,
    aws_iam_role_policy.ssm_s3,
    aws_iam_instance_profile.foundation
  ]

  lifecycle {
    create_before_destroy = false
  }
}

# Elastic IP for stable public IP
resource "aws_eip" "foundation" {
  count  = var.allocate_eip ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-foundation-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Associate EIP with instance (only when ALB is disabled)
resource "aws_eip_association" "foundation" {
  count         = var.allocate_eip && !var.enable_alb ? 1 : 0
  instance_id   = aws_instance.foundation.id
  allocation_id = aws_eip.foundation[0].id

  depends_on = [
    aws_instance.foundation,
    aws_eip.foundation
  ]
}

# =============================================================================
# Application Load Balancer Resources (when enable_alb = true)
# =============================================================================

# ACM Certificate for HTTPS
resource "aws_acm_certificate" "foundation" {
  count             = var.enable_alb ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cert"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation record for ACM
resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_alb ? {
    for dvo in aws_acm_certificate.foundation[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# ACM certificate validation
resource "aws_acm_certificate_validation" "foundation" {
  count                   = var.enable_alb ? 1 : 0
  certificate_arn         = aws_acm_certificate.foundation[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ALB Security Group
resource "aws_security_group" "alb" {
  count       = var.enable_alb ? 1 : 0
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Foundation Platform ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Application Load Balancer
resource "aws_lb" "foundation" {
  count              = var.enable_alb ? 1 : 0
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.alb_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Target Group for EC2 instances
resource "aws_lb_target_group" "foundation" {
  count    = var.enable_alb ? 1 : 0
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,302"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Register EC2 instance with target group
resource "aws_lb_target_group_attachment" "foundation" {
  count            = var.enable_alb ? 1 : 0
  target_group_arn = aws_lb_target_group.foundation[0].arn
  target_id        = aws_instance.foundation.id
  port             = 443
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  count             = var.enable_alb ? 1 : 0
  load_balancer_arn = aws_lb.foundation[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.foundation[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.foundation[0].arn
  }
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  count             = var.enable_alb ? 1 : 0
  load_balancer_arn = aws_lb.foundation[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# DNS Record pointing to ALB
resource "aws_route53_record" "foundation_alb" {
  count   = var.enable_alb ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.foundation[0].dns_name
    zone_id                = aws_lb.foundation[0].zone_id
    evaluate_target_health = true
  }
}
