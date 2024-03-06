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

