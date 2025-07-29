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
          S3_BUCKET=${var.bucket_name}
          S3_ACCESS_KEY=${var.s3_access_key}
          S3_SECRET_KEY=${var.s3_secret_key}
          S3_REGION=us-east-1
          
          # Redis Cache
          ENABLE_REDIS=${var.enable_redis}
          REDIS_PASSWORD=${random_password.redis_password.result}
          REDIS_MAX_MEMORY=${var.redis_max_memory}
          REDIS_PROFILE=${var.enable_redis ? "production" : "disabled"}
          
          # Monitoring
          SLACK_WEBHOOK_URL=${var.slack_webhook_url}
          ENABLE_MONITORING=${var.enable_slack_alerts}
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
    packages = [
      "curl",
      "git",
      "ufw",
      "fail2ban",
      "unattended-upgrades",
      "jq"
    ],
    runcmd = concat([
      # Install Docker and Docker Compose
      "curl -fsSL https://get.docker.com | sh",
      "usermod -aG docker ${var.vm_username}",
      "curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "chmod +x /usr/local/bin/docker-compose",
      
      # Add user to sudo group and configure sudoers
      "usermod -aG sudo ${var.vm_username}",
      "echo '${var.vm_username} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${var.vm_username}",
      "chmod 440 /etc/sudoers.d/${var.vm_username}",
      
      # Fix home directory ownership
      "chown -R ${var.vm_username}:${var.vm_username} /home/${var.vm_username}",
      "chmod 755 /home/${var.vm_username}",
      
      # Configure firewall
      "ufw --force enable",
      "ufw default deny incoming",
      "ufw default allow outgoing",
      "ufw allow ssh",
      "ufw allow 80/tcp",
      "ufw allow 443/tcp",
      
      # Configure fail2ban
      "systemctl enable fail2ban",
      "systemctl start fail2ban",
      
      # Configure automatic security updates
      "echo 'Unattended-Upgrade::Automatic-Reboot \"false\";' >> /etc/apt/apt.conf.d/50unattended-upgrades",
      "echo 'Unattended-Upgrade::Allowed-Origins:: \"$${distro_id}:$${distro_codename}-security\";' >> /etc/apt/apt.conf.d/50unattended-upgrades",
    ], var.git_deploy_key != "" ? [
      # Setup SSH deploy key permissions
      "mkdir -p /home/${var.vm_username}/.ssh",
      "chmod 700 /home/${var.vm_username}/.ssh",
      "chown ${var.vm_username}:${var.vm_username} /home/${var.vm_username}/.ssh",
      "chmod 600 /home/${var.vm_username}/.ssh/git_deploy_key",
      "chmod 600 /home/${var.vm_username}/.ssh/config",
      "chown ${var.vm_username}:${var.vm_username} /home/${var.vm_username}/.ssh/git_deploy_key",
      "chown ${var.vm_username}:${var.vm_username} /home/${var.vm_username}/.ssh/config",
    ] : [], [
      # Fix .env file ownership before moving it
      "chown ${var.vm_username}:${var.vm_username} /home/${var.vm_username}/.env",
      # Clone Nextcloud configuration repository
      "su - ${var.vm_username} -c \"git clone ${var.nextcloud_config_repo} /home/${var.vm_username}/nextcloud\"",
      
      # Move .env file to the correct location
      "mv /home/${var.vm_username}/.env /home/${var.vm_username}/nextcloud/.env",
      "chown ${var.vm_username}:${var.vm_username} /home/${var.vm_username}/nextcloud/.env",
      
      # Run setup script
      "su - ${var.vm_username} -c \"cd /home/${var.vm_username}/nextcloud && chmod +x setup.sh && ./setup.sh\"",
      
      # Fix permissions for configs directory to be writable by container
      "chown -R 33:33 /home/${var.vm_username}/nextcloud/configs",
      
      # Start Docker containers with production profile (includes Redis)
      "su - ${var.vm_username} -c \"cd /home/${var.vm_username}/nextcloud && docker-compose --profile production up -d\"",
      
      # Wait for Nextcloud to be ready and configure Redis
      "sleep 60",
      "su - ${var.vm_username} -c \"cd /home/${var.vm_username}/nextcloud && docker-compose exec -T app su -s /bin/sh www-data -c 'php occ config:system:set redis host --value=redis'\"",
      "su - ${var.vm_username} -c \"cd /home/${var.vm_username}/nextcloud && docker-compose exec -T app su -s /bin/sh www-data -c \\\"php occ config:system:set redis password --value='\\$(grep REDIS_PASSWORD /home/${var.vm_username}/nextcloud/.env | cut -d= -f2)'\\\"\"",
      "su - ${var.vm_username} -c \"cd /home/${var.vm_username}/nextcloud && docker-compose exec -T app su -s /bin/sh www-data -c 'php occ config:system:set redis port --value=6379'\"",
      "su - ${var.vm_username} -c \"cd /home/${var.vm_username}/nextcloud && docker-compose exec -T app su -s /bin/sh www-data -c 'php occ config:system:set memcache.local --value=\\\\\\\\OC\\\\\\\\Memcache\\\\\\\\Redis'\"",
      "su - ${var.vm_username} -c \"cd /home/${var.vm_username}/nextcloud && docker-compose exec -T app su -s /bin/sh www-data -c 'php occ config:system:set memcache.locking --value=\\\\\\\\OC\\\\\\\\Memcache\\\\\\\\Redis'\"",
      
      # Setup cron for automated backups
      "echo '0 2 * * * ${var.vm_username} cd /home/${var.vm_username}/nextcloud && ./scripts/backup.sh' | crontab -",
      
      # Setup cron for pulling latest configuration changes
      "echo '*/30 * * * * ${var.vm_username} cd /home/${var.vm_username}/nextcloud && git pull && docker-compose --profile production up -d' | crontab -u ${var.vm_username} -"
    ], var.enable_slack_alerts ? [
      # Enable health monitoring if Slack alerts are enabled
      "cp /home/${var.vm_username}/nextcloud/systemd/health-monitor.service /etc/systemd/system/",
      "systemctl daemon-reload",
      "systemctl enable health-monitor.service",
      "systemctl start health-monitor.service"
    ] : [], var.ssh_public_key != "" ? [
      # Setup SSH key permissions
      "mkdir -p /home/${var.vm_username}/.ssh",
      "chmod 700 /home/${var.vm_username}/.ssh",
      "chown ${var.vm_username}:${var.vm_username} /home/${var.vm_username}/.ssh",
      "chmod 600 /home/${var.vm_username}/.ssh/authorized_keys",
      "chown ${var.vm_username}:${var.vm_username} /home/${var.vm_username}/.ssh/authorized_keys"
    ] : [])
  })
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