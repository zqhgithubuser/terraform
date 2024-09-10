# Elastic File System
resource "aws_efs_file_system" "httpd" {
  tags = {
    Name = "${var.namespace}-efs"
  }
}

# Mount TargetA
resource "aws_efs_mount_target" "efs-mount-targetA" {
  file_system_id  = aws_efs_file_system.httpd.id
  security_groups = [ var.sg.efs.id ]
  subnet_id       = var.subnet.subnetA_id
}

# Mount TargetB
resource "aws_efs_mount_target" "efs-mount-targetB" {
  file_system_id  = aws_efs_file_system.httpd.id
  security_groups = [ var.sg.efs.id ]
  subnet_id       = var.subnet.subnetB_id
}
