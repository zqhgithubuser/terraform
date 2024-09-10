output "efs_id" {
  value = aws_efs_file_system.httpd.id
}

output "efs_mount_targetA" {
  value = aws_efs_mount_target.efs-mount-targetA
}

output "efs_mount_targetB" {
  value = aws_efs_mount_target.efs-mount-targetB
}
