output "redshift_host" {
  description = "Redshift endpoint (host:port)"
  value       = aws_redshift_cluster.this.endpoint
}

output "redshift_db" {
  description = "Redshift database name"
  value       = aws_redshift_cluster.this.database_name
}

output "redshift_user" {
  description = "Redshift master username"
  value       = aws_redshift_cluster.this.master_username
}

output "emr_master_dns" {
  description = "EMR master public DNS"
  value       = aws_emr_cluster.this.master_public_dns
}

output "ssh_command_to_emr" {
  description = "SSH command to connect to EMR master"
  value       = "ssh -i ${var.key_name}.pem hadoop@${aws_emr_cluster.this.master_public_dns}"
}
