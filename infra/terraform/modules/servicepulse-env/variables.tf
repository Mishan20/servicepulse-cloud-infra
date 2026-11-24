variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either 'dev' or 'prod'."
  }
}

variable "instance_type" {
  description = "EC2 instance type (t3.micro recommended for lowest cost / Free Tier)"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB (20GB is enough for Docker + Postgres and stays within Free Tier)"
  type        = number
  default     = 20
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID"
  type        = string
  default     = "ami-0663918c81e287db1" # Canonical Ubuntu 22.04 LTS in ap-southeast-2
}

variable "ssh_public_key" {
  description = "SSH public key string (contents of ~/.ssh/id_ed25519.pub or id_rsa.pub)"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into EC2 (use 0.0.0.0/0 if deploying from GitHub Actions runners)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
