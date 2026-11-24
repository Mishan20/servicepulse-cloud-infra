output "environment" {
  description = "Deployed environment name"
  value       = var.environment
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IPv4 address of the EC2 instance (point your Hostinger A record and GitHub EC2_HOST secret here)"
  value       = aws_instance.app.public_ip
}

output "dashboard_http_url" {
  description = "Direct HTTP URL before custom domain is configured"
  value       = "http://${aws_instance.app.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/servicepulse_aws ubuntu@${aws_instance.app.public_ip}"
}
