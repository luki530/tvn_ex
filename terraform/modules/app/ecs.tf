resource "aws_ecs_cluster" "java-app" {
  name = "java-app"
}

resource "aws_ecs_task_definition" "java-app" {
  family                   = "java-app-task"
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.java-app.arn
  execution_role_arn       = aws_iam_role.java-app-execution.arn
  requires_compatibilities = ["FARGATE", "EC2"]
  container_definitions = jsonencode(
    [
      {
        name  = "java-app"
        image = var.app_image
        portMappings = [
          {
            containerPort = 8080
            hostPort      = 8080
          }
        ]
      }
    ]
  )
}

resource "aws_ecs_service" "java-app" {
  name                               = "java-app"
  cluster                            = aws_ecs_cluster.java-app.id
  task_definition                    = aws_ecs_task_definition.java-app.id
  desired_count                      = 3
  health_check_grace_period_seconds  = 300
  launch_type                        = "FARGATE"
  platform_version                   = "1.4.0"
  deployment_minimum_healthy_percent = 30
  deployment_maximum_percent         = 100
  network_configuration {
    assign_public_ip = false
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.java-app-ecs.id]
  }
  load_balancer {
    container_name   = "java-app"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.java-app-tg.arn
  }
}

resource "aws_lb_target_group" "java-app-tg" {
  name = "java-app-tg"
  health_check {
    path = "/demo/Hello"
  }
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10
}

resource "aws_security_group" "java-app-ecs" {
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ecs-ingress" {
  security_group_id        = aws_security_group.java-app-ecs.id
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.java-app-lb.id
}

resource "aws_security_group" "java-app-lb" {
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "lb-ingress" {
  security_group_id = aws_security_group.java-app-lb.id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["89.64.36.196/32"]
}

resource "aws_security_group_rule" "lb-egress" {
  security_group_id        = aws_security_group.java-app-lb.id
  type                     = "egress"
  protocol                 = "TCP"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.java-app-ecs.id
}

resource "aws_lb" "java-app-alb" {
  subnets         = var.public_subnets
  security_groups = [aws_security_group.java-app-lb.id]
}

resource "aws_lb_listener" "alb-listener" {
  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.java-app-tg.arn
      }
    }
  }
  load_balancer_arn = aws_lb.java-app-alb.arn
  port              = 80
  protocol          = "HTTP"
}
