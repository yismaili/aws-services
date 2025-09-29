# Outputs
output "instance_ip" {
  value       = aws_instance.main.public_ip
  description = "Public IP address of the instance"
}

output "ssh_command" {
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_instance.main.public_ip}"
  description = "SSH command to connect to the instance"
}

output "ebs_volume_id" {
  value       = aws_ebs_volume.data.id
  description = "ID of the EBS data volume"
}

output "data_mount_point" {
  value       = "/data"
  description = "Mount point for the EBS volume"
}