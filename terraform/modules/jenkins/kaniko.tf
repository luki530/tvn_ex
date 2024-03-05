resource "aws_s3_bucket" "kaniko-context" {
  bucket = "kaniko-context-bucket"
}

resource "aws_ecr_repository" "app-repository" {
  name = "app-repository"
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
          aws_ecr_repository.app-repository.arn,
          format("%s/*", aws_ecr_repository.app-repository.arn),
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
          "s3:GetObject",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.kaniko-context.arn
        ]
      },
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

resource "aws_ecs_task_definition" "kaniko" {
  family                   = "kaniko-builder"
  cpu                      = 512
  memory                   = 1024
  task_role_arn            = aws_iam_role.kaniko.arn
  execution_role_arn       = aws_iam_role.kaniko-execution.arn
  requires_compatibilities = ["FARGATE", "EC2"]
  network_mode             = "awsvpc"
  container_definitions = jsonencode(
    [
      {
        name  = "kaniko-builder"
        image = var.kaniko_image
        logConfiguration = {
          "logDriver" = "awslogs"
          "options" = {
            "awslogs-group"         = aws_cloudwatch_log_group.jenkins-cw.id
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "kaniko"
          }
        }
        environment = [
          { "name" : "AWS_SDK_LOAD_CONFIG", "value" : "true" },
          { "name" : "AWS_EC2_METADATA_DISABLED", "value" : "true" },
        ]
      }
    ]
  )
}

resource "aws_security_group" "kaniko" {
  vpc_id = var.vpc_id
  name   = "kaniko-sg"
}
