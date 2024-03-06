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
