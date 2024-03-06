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
