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

resource "aws_lb_target_group" "jenkins-tg" {
  name = "jenkins-tg"
  health_check {
    path = "/login"
  }
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10
}

resource "aws_security_group" "jenkins-ecs" {
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ecs-ingress" {
  security_group_id        = aws_security_group.jenkins-ecs.id
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.jenkins-lb.id
}

resource "aws_security_group" "jenkins-lb" {
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "lb-ingress" {
  security_group_id = aws_security_group.jenkins-lb.id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["89.64.36.196/32"]
}

resource "aws_security_group_rule" "lb-egress" {
  security_group_id        = aws_security_group.jenkins-lb.id
  type                     = "egress"
  protocol                 = "TCP"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.jenkins-ecs.id
}

resource "aws_cloudwatch_log_group" "jenkins-cw" {
  name              = "jenkins-ecs"
  retention_in_days = 14
}

resource "aws_lb" "jenkins-alb" {
  subnets         = var.public_subnets
  security_groups = [aws_security_group.jenkins-lb.id]
}

resource "aws_lb_listener" "alb-listener" {
  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.jenkins-tg.arn
      }
    }
  }
  load_balancer_arn = aws_lb.jenkins-alb.arn
  port              = 80
  protocol          = "HTTP"
}
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

resource "aws_security_group" "efs-sg" {
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "efs-ingress" {
  security_group_id        = aws_security_group.efs-sg.id
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.jenkins-ecs.id
}
