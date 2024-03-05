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
      {
        "Action" : [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:DeleteObject"
        ]
        "Resource" : format("%s/*", aws_s3_bucket.kaniko-context.arn),
        "Effect" : "Allow"
      },
      {
        "Action" : "ecs:RunTask",
        "Resource" : "arn:aws:ecs:*:*:task-definition/kaniko-builder:*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "ecs:DescribeTasks",
          "ecs:ListTaskDefinitions"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : "iam:PassRole",
        "Resource" : [
          aws_iam_role.kaniko.arn,
          aws_iam_role.kaniko-execution.arn
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "ecs:DescribeServices",
          "ecs:UpdateService",
        ]
        "Resource" : [
          "*"
        ],
        "Effect" : "Allow"
      }
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
