resource "aws_security_group" "this" {
  name   = var.name
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ingress_rules" {
  for_each = var.ingress_rules

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.allow_cidrs
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "egress_default" {
  count = length(var.egress_rules) == 0 ? 1 : 0

  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "egress_rules" {
  for_each = var.egress_rules

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.allow_cidrs
  security_group_id = aws_security_group.this.id
}
