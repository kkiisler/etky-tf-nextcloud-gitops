# Pilvio provider variables
variable "apikey" {
  description = "Pilvio API key (sensitive)"
  type        = string
  sensitive   = true
}

variable "host" {
  description = "Pilvio API endpoint"
  type        = string
  default     = "api.pilvio.com"
}

variable "location" {
  description = "Pilvio location (Allowed: 'tll01', 'jhvi', 'jhv02')"
  type        = string
  default     = "tll01"
}

variable "billing_account_id" {
  description = "Pilvio billing account ID"
  type        = number
}

# VPC and VM
variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "nextcloud-vpc"
}

variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "nextcloud"
}

variable "vm_os_name" {
  description = "VM OS (e.g., ubuntu)"
  type        = string
  default     = "ubuntu"
}

variable "vm_os_version" {
  description = "VM OS version (e.g., 22.04)"
  type        = string
  default     = "22.04"
}

variable "vm_username" {
  description = "Admin username"
  type        = string
  default     = "adminuser"
}

variable "vm_password" {
  description = "Admin password (sensitive) - auto-generated if not provided"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key for passwordless access (optional but recommended)"
  type        = string
  default     = ""
}

variable "vm_memory" {
  description = "RAM in MB"
  type        = number
  default     = 2048
}

variable "vm_vcpu" {
  description = "vCPU count"
  type        = number
  default     = 2
}

variable "vm_disk_size" {
  description = "Root disk size (GB)"
  type        = number
  default     = 40
}

# Nextcloud/MariaDB/Stack config
variable "db_user" {
  description = "Nextcloud/MySQL DB user"
  type        = string
  default     = "nextcloud"
}

variable "db_password" {
  description = "Nextcloud/MySQL DB password - auto-generated if not provided"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_root_password" {
  description = "MySQL root password - auto-generated if not provided"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nextcloud_admin_user" {
  description = "Nextcloud admin username"
  type        = string
  default     = "admin"
}

variable "nextcloud_admin_password" {
  description = "Nextcloud admin password - auto-generated if not provided"
  type        = string
  sensitive   = true
  default     = ""
}

variable "bucket_name" {
  description = "Pilvio S3 bucket for Nextcloud object storage (globally unique!)"
  type        = string
  default     = "nextcloud-data-bucket-1234"
}

variable "s3_access_key" {
  description = "Pilvio S3 access key for object storage"
  type        = string
  sensitive   = true
}

variable "s3_secret_key" {
  description = "Pilvio S3 secret key for object storage"
  type        = string
  sensitive   = true
}

variable "s3_endpoint" {
  description = "Pilvio S3 endpoint URL"
  type        = string
  default     = "s3.pilw.io"
}

variable "floatingip_name" {
  description = "Name of the Floating IP"
  type        = string
  default     = "nextcloud-fip"
}

# Domain configuration
variable "domain_name" {
  description = "Domain name for Let's Encrypt SSL certificate (e.g., nextcloud.example.com)"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt notifications"
  type        = string
}

# Slack monitoring configuration
variable "slack_webhook_url" {
  description = "Slack webhook URL for health monitoring alerts (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_slack_alerts" {
  description = "Enable Slack notifications for health monitoring"
  type        = bool
  default     = false
}

# Redis configuration
variable "enable_redis" {
  description = "Enable Redis cache for improved performance"
  type        = bool
  default     = true
}

variable "redis_max_memory" {
  description = "Maximum memory for Redis cache (e.g., '512mb', '1gb')"
  type        = string
  default     = "512mb"
}

# GitOps configuration
variable "nextcloud_config_repo" {
  description = "Git repository URL containing Nextcloud docker-compose configuration (use SSH format for private repos: git@github.com:user/repo.git)"
  type        = string
  default     = "https://github.com/yourusername/nextcloud-configs.git"
}

variable "git_deploy_key" {
  description = "SSH private key for accessing private Git repositories (deploy key)"
  type        = string
  default     = ""
  sensitive   = true
}
