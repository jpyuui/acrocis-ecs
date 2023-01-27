resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster}/${var.service}"
  role_arn           = var.role_arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

#Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "ecs_policy_down" {
  name               = "scale-down"
  policy_type        = "StepScaling"
  resource_id        = "service/${var.cluster}/${var.service}"
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

#Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "ecs_policy_up" {
  name               = "scale-up"
  policy_type        = "StepScaling"
  resource_id        = "service/${var.cluster}/${var.service}"
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = 1
    }
  }
}


resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    ClusterName = var.cluster
    ServiceName = var.service
  }

  alarm_actions = [aws_appautoscaling_policy.ecs_policy_up.arn]
}



resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    ClusterName = var.cluster
    ServiceName = var.service
  }

  alarm_actions = [aws_appautoscaling_policy.ecs_policy_down.arn]
}





