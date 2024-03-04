resource "aws_iam_role" "jenkins" {
  name = "jenkins-role"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid    = ""
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
        },
      ]
    }
  )
}

resource "aws_iam_role_policy" "jenkins" {
  name = "jenkins-policy"
  role = aws_iam_role.jenkins.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "jenkins-execution" {
  name = "jenkins-execution-role"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid    = ""
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
        },
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "jenkins-execution" {
  role       = aws_iam_role.jenkins-execution.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
