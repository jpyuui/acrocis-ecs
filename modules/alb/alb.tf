# =================
# ALB
# =================
locals {
  default_action_503 = {
    type         = "fixed-response"
    content_type = "text/plain"
    status_code  = "503"
    message_body = "Service Temporarily Unavailable"
  }
}

resource "aws_alb" "this" {
  name                       = "${var.name}-alb-${var.env}"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = true
  subnets                    = var.subnet_ids
  security_groups            = var.security_group_ids

  access_logs {
    bucket  = aws_s3_bucket.alb_log.bucket
    prefix  = "${var.name}-${var.env}"
    enabled = true
  }
}

resource "aws_alb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_alb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  certificate_arn   = lookup(each.value, "certificate_arn", null)
  ssl_policy        = lookup(each.value, "ssl_policy", null)

  default_action {
    type = local.default_action_503.type

    fixed_response {
      content_type = local.default_action_503.content_type
      status_code  = local.default_action_503.status_code
      message_body = local.default_action_503.message_body
    }
  }
}

resource "aws_alb_target_group" "this" {
  for_each = var.target_groups

  vpc_id               = var.vpc_id
  name_prefix          = each.value.name_prefix
  target_type          = each.value.target_type
  port                 = each.value.port
  protocol             = each.value.protocol
  deregistration_delay = each.value.deregistration_delay

  health_check {
    path                = each.value.health_check_config.path
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_alb.this,
  ]
}

resource "aws_alb_listener_rule" "this" {
  for_each = {
    for rule_name, rule in flatten(
      [
        for l_name, l in var.listeners :
        [for r in l.rules : { listener_name = l_name, rule = [r] }]
      ]
    ) : rule_name => rule
  }

  listener_arn = aws_alb_listener.this[each.value.listener_name].arn
  priority     = each.value.rule[0].priority


  /*
    action
  */

  # actionがredirectの場合
  dynamic "action" {
    for_each = [
      for rule in each.value.rule : rule
      if rule.type == "redirect"
    ]

    content {
      type = "redirect"
      redirect {
        port        = action.value.redirect_config.port
        protocol    = action.value.redirect_config.protocol
        status_code = action.value.redirect_config.status_code
        host        = lookup(action.value.redirect_config, "host", null)
        path        = lookup(action.value.redirect_config, "path", null)
        query       = lookup(action.value.redirect_config, "query", null)
      }
    }
  }

  # actionがfixed-responseの場合
  dynamic "action" {
    for_each = [
      for rule in each.value.rule :
      rule
      if rule.type == "fixed-response"
    ]

    content {
      type = "fixed-response"
      fixed_response {
        content_type = action.value.fixed_response_config.content_type
        status_code  = action.value.fixed_response_config.status_code
        message_body = action.value.fixed_response_config.message_body
      }
    }
  }

  # actionがforwardの場合
  dynamic "action" {
    for_each = [
      for rule in each.value.rule : rule
      if rule.type == "forward"
    ]

    content {
      type             = "forward"
      target_group_arn = aws_alb_target_group.this[action.value.forward_config.target_group_name].arn
    }
  }


  /*
    condition
  */

  # path_patternの条件
  dynamic "condition" {
    for_each = [
      for rule in each.value.rule : rule
      if length(lookup(rule.conditions, "path_patterns", [])) > 0
    ]

    content {
      path_pattern {
        values = condition.value.conditions.path_patterns
      }
    }
  }

  # http_headerの条件
  dynamic "condition" {
    for_each = [
      for rule in each.value.rule : rule
      if length(lookup(rule.conditions, "http_headers", [])) > 0
    ]

    content {
      dynamic "http_header" {
        for_each = condition.value.conditions.http_headers

        content {
          http_header_name = http_header.value.name
          values           = http_header.value.values
        }
      }
    }
  }
}
