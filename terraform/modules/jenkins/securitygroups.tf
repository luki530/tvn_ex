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

resource "aws_security_group_rule" "ecs-egress-443" {
  security_group_id = aws_security_group.jenkins-ecs.id
  type              = "egress"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ecs-egress-nfs" {
  security_group_id        = aws_security_group.jenkins-ecs.id
  type                     = "egress"
  protocol                 = "TCP"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.efs-sg.id
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


resource "aws_security_group" "kaniko" {
  vpc_id = var.vpc_id
  name   = "kaniko-sg"
}

resource "aws_security_group_rule" "kaniko-egress-443" {
  security_group_id = aws_security_group.kaniko.id
  type              = "egress"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "kaniko-egress-80" {
  security_group_id = aws_security_group.kaniko.id
  type              = "egress"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}
