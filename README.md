# Terraform Nextcloud GitOps

This repository contains Terraform configuration for deploying Nextcloud on Pilvio cloud infrastructure using a GitOps approach. Instead of embedding application configuration directly in Terraform, this setup pulls configuration from a separate Git repository, following infrastructure-as-code best practices.

## Architecture

### Infrastructure Components
- **VPC** - Network isolation for the deployment
- **Virtual Machine** - Ubuntu 22.04 with Docker, UFW firewall, Fail2ban
- **S3 Bucket** - Object storage for Nextcloud data
- **Floating IP** - Public IP for external access

### GitOps Workflow
1. Infrastructure provisioned by Terraform
2. VM pulls docker-compose configuration from Git repository
3. Configuration updates are applied automatically via cron job
4. Changes to application config don't require Terraform runs

## Prerequisites

1. Pilvio account with API credentials
2. Domain name with DNS management access
3. Git repository with Nextcloud configuration (e.g., [nextcloud-configs](https://github.com/yourusername/nextcloud-configs))

### Setting up Deploy Keys for Private Repositories

If your configuration repository is private, you'll need to set up SSH deploy keys:

1. **Generate a deploy key:**
   ```bash
   ssh-keygen -t ed25519 -f nextcloud-deploy-key -N ""
   ```

2. **Add the public key to your Git repository:**
   - GitHub: Settings → Deploy keys → Add deploy key
   - GitLab: Settings → Repository → Deploy keys → Add key
   - Give it read-only access

3. **Add the private key to terraform.tfvars:**
   ```hcl
   git_deploy_key = file("nextcloud-deploy-key")
   # Or inline:
   git_deploy_key = <<-EOT
   -----BEGIN OPENSSH PRIVATE KEY-----
   [your key content]
   -----END OPENSSH PRIVATE KEY-----
   EOT
   ```

4. **Update repository URL to SSH format:**
   ```hcl
   nextcloud_config_repo = "git@github.com:yourusername/nextcloud-configs.git"
   ```

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/yourusername/tf-nextcloud-gitops.git
   cd tf-nextcloud-gitops
   ```

2. **Copy and configure terraform.tfvars:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize and apply Terraform:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Update DNS:**
   Point your domain's A record to the floating IP shown in terraform output.

5. **Access Nextcloud:**
   After DNS propagation, access your instance at `https://your-domain.com`

## Configuration

### Required Variables

| Variable | Description |
|----------|-------------|
| `apikey` | Your Pilvio API key |
| `billing_account_id` | Your Pilvio billing account ID |
| `domain_name` | Domain for SSL certificate (e.g., nextcloud.example.com) |
| `letsencrypt_email` | Email for Let's Encrypt notifications |
| `s3_access_key` | Pilvio S3 access key |
| `s3_secret_key` | Pilvio S3 secret key |
| `nextcloud_config_repo` | Git repository URL with docker-compose config |
| `git_deploy_key` | SSH deploy key for private repositories (optional) |

### Optional Variables

See `variables.tf` for all available configuration options including:
- VM resources (CPU, RAM, disk)
- Redis cache settings
- Slack monitoring integration
- SSH key for secure access

## Application Updates

To update Nextcloud or modify configuration:

1. Make changes in your nextcloud-configs repository
2. Commit and push to Git
3. Changes are automatically pulled every 30 minutes
4. For immediate updates, SSH to VM and run:
   ```bash
   cd ~/nextcloud && git pull && docker-compose up -d
   ```

## Security Features

- Automatic security updates via unattended-upgrades
- UFW firewall (only SSH, HTTP, HTTPS allowed)
- Fail2ban for brute-force protection
- Let's Encrypt SSL with auto-renewal
- Secure password generation for all services

## Monitoring

When Slack alerts are enabled:
- Health checks every 60 seconds
- Alerts for service failures, high disk/memory usage
- SSL certificate expiry warnings
- Container health monitoring

## Backup

Daily automated backups at 2 AM local time:
- Database dumps to `/home/adminuser/backups/`
- Nextcloud data stored in S3 (inherently durable)

## Outputs

After successful deployment:
```
vm_id             = "uuid-of-vm"
vm_private_ip     = "10.x.x.x"
floating_ip       = "public-ip-address"
nextcloud_url     = "https://your-domain.com"
admin_username    = "admin"
```

Admin password is stored in Terraform state - retrieve with:
```bash
terraform output -raw nextcloud_admin_password
```

## Troubleshooting

1. **Check cloud-init logs:**
   ```bash
   ssh adminuser@your-ip
   sudo tail -f /var/log/cloud-init-output.log
   ```

2. **Check container logs:**
   ```bash
   cd ~/nextcloud
   docker-compose logs -f
   ```

3. **Verify services:**
   ```bash
   docker-compose ps
   curl -I https://your-domain.com/health
   ```

## Destroy

To completely remove all resources:
```bash
terraform destroy
```

**Warning:** This will delete all data including the S3 bucket!

## License

MIT License - See LICENSE file for details