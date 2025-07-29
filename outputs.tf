output "nextcloud_vm_id" {
  description = "The UUID of the Nextcloud VM."
  value       = pilvio_vm.nextcloud.uuid
}

output "nextcloud_vm_private_ip" {
  description = "Private IPv4 address of the VM."
  value       = pilvio_vm.nextcloud.private_ipv4
}

output "nextcloud_vm_public_ip" {
  description = "Floating/Public IP address of the VM."
  value       = pilvio_floatingip.nextcloud.address
}

output "nextcloud_s3_bucket_name" {
  description = "Name of the created S3-compatible bucket for Nextcloud."
  value       = pilvio_bucket.nextcloud.name
}

# Sensitive outputs - passwords
output "vm_password" {
  description = "VM admin password (sensitive)"
  value       = random_password.vm_password.result
  sensitive   = true
}

output "nextcloud_admin_password" {
  description = "Nextcloud admin password (sensitive)"
  value       = random_password.nextcloud_admin_password.result
  sensitive   = true
}

output "db_root_password" {
  description = "Database root password (sensitive)"
  value       = random_password.db_root_password.result
  sensitive   = true
}

output "access_instructions" {
  description = "Instructions for accessing Nextcloud"
  value = <<-EOT
    
    Nextcloud has been deployed successfully!
    
    1. Point your domain (${var.domain_name}) to IP: ${pilvio_floatingip.nextcloud.address}
    2. Access Nextcloud at: https://${var.domain_name}
    3. Login credentials:
       - Username: ${var.nextcloud_admin_user}
       - Password: Use 'terraform output nextcloud_admin_password' to retrieve
    
    VM SSH access:
       - Username: ${var.vm_username}
       - Password: Use 'terraform output vm_password' to retrieve
       - SSH Key: ${var.ssh_public_key != "" ? "Configured" : "Not configured - using password authentication"}
    
    Note: Let's Encrypt SSL certificate will be automatically provisioned when you access the domain.
  EOT
}

output "slack_monitoring_status" {
  description = "Slack monitoring configuration status"
  value = var.enable_slack_alerts ? "Enabled - Health monitoring alerts will be sent to your configured Slack webhook" : "Disabled - Set enable_slack_alerts to true and provide slack_webhook_url to enable"
}

output "health_monitoring_instructions" {
  description = "Health monitoring and alerting information"
  value = <<-EOT
    
    Health Monitoring Status: ${var.enable_slack_alerts ? "ACTIVE" : "INACTIVE"}
    
    Health Check Endpoints:
    - Simple health check: https://${var.domain_name}/health
    - Detailed health API: SSH to server and run: /usr/local/bin/health-check-api.sh
    
    ${var.enable_slack_alerts ? 
    "Slack Alerts Configuration:\n    - Alerts are enabled and will be sent to your configured webhook\n    - Monitoring includes: Nextcloud HTTP, Docker containers, disk space, database, Redis cache, SSL certificate, memory usage\n    - Check interval: 60 seconds\n    - Alert threshold: 2 consecutive failures before alerting\n    - Rate limiting: Maximum 1 alert per hour per service\n    \n    To view monitoring logs:\n    - SSH to server and run: journalctl -u health-monitor -f\n    \n    To manually test Slack webhook:\n    - SSH to server and run: systemctl restart health-monitor" : 
    "To enable Slack alerts:\n    1. Set enable_slack_alerts = true in your terraform.tfvars\n    2. Set slack_webhook_url = \"https://hooks.slack.com/services/YOUR/WEBHOOK/URL\"\n    3. Run terraform apply"}
  EOT
}

output "redis_status" {
  description = "Redis cache configuration status"
  value = var.enable_redis ? "Enabled - Redis cache is configured for improved performance" : "Disabled - Redis cache is not enabled"
}
