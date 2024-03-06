output "ecr_arn" {
  value = aws_ecr_repository.app-repository.arn
}

output "ecr_url" {
  value = aws_ecr_repository.app-repository.repository_url
}
