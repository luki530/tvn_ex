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
        Effect = "Allow"
        Resource = [
          aws_efs_file_system.fs.arn
        ]
      },
      {
        "Action" = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:DeleteObject"
        ]
        "Resource" = [
          format("%s/*", aws_s3_bucket.kaniko-context.arn),
        ]
        "Effect" = "Allow"
      },
      {
        "Action" = [
          "ecs:RunTask",
        ]
        "Resource" = format("arn:aws:ecs:*:*:task-definition/%s:*", aws_ecs_task_definition.kaniko.family),
        "Effect"   = "Allow"
      },
      {
        "Action" : [
          "ecs:DescribeTasks",
          "ecs:ListTaskDefinitions"
        ],
        "Resource" = "*",
        "Effect"   = "Allow"
      },
      {
        "Action" = [
          "iam:PassRole"
        ],
        "Resource" = [
          aws_iam_role.kaniko.arn,
          aws_iam_role.kaniko-execution.arn
        ],
        "Effect" = "Allow"
      },
      {
        "Action" = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
        ]
        "Resource" = [
          "arn:aws:ecs:*:*:service/java-app/java-app"
        ],
        "Effect" = "Allow"
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

resource "aws_iam_role" "kaniko" {
  name = "kaniko-role"
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

resource "aws_iam_role_policy" "kaniko" {
  name = "kaniko-policy"
  role = aws_iam_role.kaniko.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
        ]
        Effect = "Allow"
        Resource = [
          format("%s/*", aws_s3_bucket.kaniko-context.arn)
        ]
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
        ]
        Effect = "Allow"
        Resource = [
          aws_ecr_repository.app-repository.arn
        ]
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "kaniko-execution" {
  name = "kaniko-execution-role"
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

resource "aws_iam_role_policy" "kaniko-execution" {
  name = "kaniko-execution-policy"
  role = aws_iam_role.kaniko-execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}
