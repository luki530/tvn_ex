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
