# Generate secure random passwords
resource "random_password" "db_password" {
  length  = 32
  special = true
  # Avoid shell metacharacters and characters that cause issues in docker-compose.yml
  override_special = "!@#-_=+:?"
}

resource "random_password" "db_root_password" {
  length  = 32
  special = true
  # Avoid shell metacharacters and characters that cause issues in docker-compose.yml
  override_special = "!@#-_=+:?"
}

resource "random_password" "nextcloud_admin_password" {
  length  = 20
  special = true
  # Avoid shell metacharacters and characters that cause issues in docker-compose.yml
  override_special = "!@#-_=+:?"
}

resource "random_password" "vm_password" {
  length  = 20
  special = true
  # Avoid shell metacharacters and characters that cause issues in docker-compose.yml
  override_special = "!@#-_=+:?"
}

resource "random_password" "redis_password" {
  length  = 32
  special = true
  # Avoid shell metacharacters and characters that cause issues in docker-compose.yml
  override_special = "!@#-_=+:?"
}

# Create a VPC for the VM
resource "pilvio_vpc" "main" {
  name     = var.vpc_name
  location = var.location # "tll01", "jhvi", "jhv02"
}

# Create the VM and bootstrap Nextcloud with Docker Compose
resource "pilvio_vm" "nextcloud" {
  name               = var.vm_name
  os_name            = var.vm_os_name
  os_version         = var.vm_os_version
  memory             = var.vm_memory
  vcpu               = var.vm_vcpu
  username           = var.vm_username
  password           = random_password.vm_password.result
  disks              = var.vm_disk_size
  billing_account_id = var.billing_account_id
  location           = var.location
  network_uuid       = pilvio_vpc.main.uuid

  cloud_init = jsonencode({
    write_files = concat([
      {
        path        = "/home/${var.vm_username}/.env"
        permissions = "0600"
        content     = <<-EOT
          # Domain Configuration
          DOMAIN_NAME=${var.domain_name}
          LETSENCRYPT_EMAIL=${var.letsencrypt_email}
          PUBLIC_IP=${pilvio_floatingip.nextcloud.address}
          
          # Database Configuration
          DB_USER=${var.db_user}
          DB_PASSWORD=${random_password.db_password.result}
          DB_ROOT_PASSWORD=${random_password.db_root_password.result}
          
          # Nextcloud Admin
          NEXTCLOUD_ADMIN_USER=${var.nextcloud_admin_user}
          NEXTCLOUD_ADMIN_PASSWORD=${random_password.nextcloud_admin_password.result}
          NEXTCLOUD_VERSION=28
          
          # S3 Object Storage
          S3_ENDPOINT=${var.s3_endpoint}
          S3_BUCKET=${pilvio_bucket.nextcloud.name}
          S3_ACCESS_KEY=${var.s3_access_key}
          S3_SECRET_KEY=${var.s3_secret_key}
          S3_REGION=us-east-1
          
          # Redis Cache
          ENABLE_REDIS=${var.enable_redis}
          REDIS_PASSWORD=${random_password.redis_password.result}
          REDIS_MAX_MEMORY=${var.redis_max_memory}
          REDIS_PROFILE=${var.enable_redis ? "production" : "disabled"}
          REDIS_HOST=${var.enable_redis ? "redis" : ""}
          REDIS_HOST_PASSWORD=${var.enable_redis ? random_password.redis_password.result : ""}
          
          # Monitoring
          SLACK_WEBHOOK_URL=${var.slack_webhook_url}
          ENABLE_MONITORING=${var.enable_slack_alerts}
        EOT
      },
      {
        path        = "/tmp/cloud-init-wrapper.sh"
        permissions = "0755"
        content     = <<-EOT
          #!/bin/bash
          # Download and execute the cloud-init wrapper from the config repo
          set -euo pipefail
          
          # Install required packages first
          apt-get update
          apt-get install -y curl git
          
          # Clone the config repo temporarily to get the wrapper script
          git clone ${var.nextcloud_config_repo} /tmp/nextcloud-configs
          
          # Execute the wrapper script
          bash /tmp/nextcloud-configs/scripts/cloud-init-wrapper.sh "${var.vm_username}" "${var.nextcloud_config_repo}"
          
          # Cleanup
          rm -rf /tmp/nextcloud-configs
        EOT
      }
    ], var.git_deploy_key != "" ? [{
      path        = "/home/${var.vm_username}/.ssh/git_deploy_key"
      permissions = "0600"
      content     = var.git_deploy_key
    }, {
      path        = "/home/${var.vm_username}/.ssh/config"
      permissions = "0600"
      content     = <<-EOT
        Host github.com
          HostName github.com
          User git
          IdentityFile ~/.ssh/git_deploy_key
          StrictHostKeyChecking no
        
        Host gitlab.com
          HostName gitlab.com
          User git
          IdentityFile ~/.ssh/git_deploy_key
          StrictHostKeyChecking no
        
        Host bitbucket.org
          HostName bitbucket.org
          User git
          IdentityFile ~/.ssh/git_deploy_key
          StrictHostKeyChecking no
      EOT
    }] : [], var.ssh_public_key != "" ? [{
      path        = "/home/${var.vm_username}/.ssh/authorized_keys"
      permissions = "0600"
      content     = var.ssh_public_key
    }] : []),
    runcmd = [
      # Execute the wrapper script
      "bash /tmp/cloud-init-wrapper.sh"
    ]
  })

  lifecycle {
    ignore_changes = [cloud_init]
  }
}

# Create an S3-compatible bucket for Nextcloud
resource "pilvio_bucket" "nextcloud" {
  name               = var.bucket_name
  billing_account_id = var.billing_account_id
}

# Allocate a Floating IP for the VM
resource "pilvio_floatingip" "nextcloud" {
  name               = var.floatingip_name
  billing_account_id = var.billing_account_id
  location           = var.location
}

# Assign Floating IP to the VM
resource "pilvio_floatingip_assignment" "nextcloud" {
  address     = pilvio_floatingip.nextcloud.address
  assigned_to = pilvio_vm.nextcloud.uuid
  location    = var.location
}