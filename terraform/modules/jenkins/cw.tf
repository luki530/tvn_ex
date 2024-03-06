resource "aws_cloudwatch_log_group" "jenkins-cw" {
  name              = "jenkins-ecs"
  retention_in_days = 14
}
