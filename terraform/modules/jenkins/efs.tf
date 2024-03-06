resource "aws_efs_file_system" "fs" {
  encrypted = true
  tags = {
    "Name" = "jenkins-home"
  }
}

resource "aws_efs_mount_target" "efs-mt" {
  for_each        = toset(var.private_subnets)
  file_system_id  = aws_efs_file_system.fs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs-sg.id]
}

resource "aws_efs_access_point" "efs-ap" {
  file_system_id = aws_efs_file_system.fs.id
  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
    path = "/jenkins-home"
  }
}
