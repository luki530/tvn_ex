resource "aws_ecs_cluster" "jenkins" {
  name = "jenkins"
}

resource "aws_ecs_task_definition" "jenkins_root" {
  family                   = "jenkins-root-task"
  cpu                      = 2048
  memory                   = 4096
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.jenkins.arn
  execution_role_arn       = aws_iam_role.jenkins-execution.arn
  requires_compatibilities = ["FARGATE", "EC2"]
  container_definitions = jsonencode(
    [
      {
        name  = "jenkins"
        image = var.jenkins_image
        portMappings = [
          {
            containerPort = 8080
            hostPort      = 8080
          }
        ]
        mountPoints = [
          {
            sourceVolume  = "jenkins-home"
            containerPath = "/var/jenkins_home"
          }
        ]
        logConfiguration = {
          "logDriver" = "awslogs"
          "options" = {
            "awslogs-group"         = aws_cloudwatch_log_group.jenkins-cw.id
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "jenkins"
          }
        }
        environment = [
          { "name" : "KANIKO_CLUSTER_NAME", "value" : aws_ecs_cluster.jenkins.name },
          { "name" : "KANIKO_SUBNET_ID", "value" : var.private_subnets[0] },
          { "name" : "KANIKO_SECURITY_GROUP_ID", "value" : aws_security_group.kaniko.id },
          { "name" : "KANIKO_BUILD_CONTEXT_BUCKET_NAME", "value" : aws_s3_bucket.kaniko-context.id },
          { "name" : "KANIKO_REPOSITORY_URI", "value" : aws_ecr_repository.app-repository.repository_url },
          { "name" : "KANIKO_ECS_FAMILY", "value" : aws_ecs_task_definition.kaniko.family },
          { "name" : "KANIKO_JENKINS_CLUSTER_NAME", "value" : aws_ecs_cluster.jenkins.name },
        ]
      }
    ]
  )
  volume {
    name = "jenkins-home"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.fs.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.efs-ap.id
        iam             = "ENABLED"
      }
    }
  }
}

resource "aws_ecs_service" "jenkins" {
  name                               = "jenkins"
  cluster                            = aws_ecs_cluster.jenkins.id
  task_definition                    = aws_ecs_task_definition.jenkins_root.id
  desired_count                      = 1
  health_check_grace_period_seconds  = 300
  launch_type                        = "FARGATE"
  platform_version                   = "1.4.0"
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  network_configuration {
    assign_public_ip = false
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.jenkins-ecs.id]
  }
  load_balancer {
    container_name   = "jenkins"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.jenkins-tg.arn
  }
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
