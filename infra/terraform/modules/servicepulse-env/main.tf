locals {
  name_prefix = "servicepulse-${var.environment}"
  common_tags = {
    Project     = "ServicePulse"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# SSH Key Pair (managed by Terraform so destroy cleans it up)
# ------------------------------------------------------------------------------
resource "aws_key_pair" "deploy" {
  key_name   = "${local.name_prefix}-key"
  public_key = var.ssh_public_key
  tags       = local.common_tags
}

# ------------------------------------------------------------------------------
# Security Group (minimal exposed ports: 22 SSH, 80 HTTP, 443 HTTPS)
# ------------------------------------------------------------------------------
resource "aws_security_group" "app_sg" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for ServicePulse (${var.environment})"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    description = "HTTP (Caddy reverse proxy & ACME challenge)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS (Caddy automatic SSL)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic (GHCR pulls, MongoDB Atlas, monitor probes)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg"
  })
}

# ------------------------------------------------------------------------------
# EC2 Instance (Free-tier friendly t3.micro + 2GB swap + clean destroy)
# ------------------------------------------------------------------------------
resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.deploy.key_name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-root-vol"
    })
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # 1. Add 2GB swapfile so t3.micro (1GB RAM) runs all containers comfortably
    if [ ! -f /swapfile ]; then
      fallocate -l 2G /swapfile
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile none swap sw 0 0' >> /etc/fstab
      sysctl vm.swappiness=20
      echo 'vm.swappiness=20' >> /etc/sysctl.conf
    fi

    # 2. Install Docker & Docker Compose plugin
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable --now docker
    usermod -aG docker ubuntu

    # 3. Prepare application directory
    mkdir -p /opt/servicepulse
    chown -R ubuntu:ubuntu /opt/servicepulse

    echo "ServicePulse (${var.environment}) bootstrap completed at $(date -u)" > /var/log/servicepulse-init.log
  EOF

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2"
  })
}
