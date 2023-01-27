# =================
# ECS
# =================
resource "aws_ecs_service" "this" {
  name                   = "${var.service_config.name}-service-${var.env}"
  cluster                = var.cluster_id
  task_definition        = aws_ecs_task_definition.this.arn
  desired_count          = var.service_config.desired_count
  launch_type            = var.launch_type
  enable_execute_command = var.service_config.enable_execute_command

  dynamic "network_configuration" {
    for_each = [
      for config in lookup(var.service_config, "network_config", {}) : config
    ]

    content {
      security_groups  = network_configuration.value.security_group_ids
      subnets          = network_configuration.value.subnet_ids
      assign_public_ip = network_configuration.value.assign_public_ip
    }
  }

  dynamic "load_balancer" {
    for_each = [
      for config in lookup(var.service_config, "load_balancer_config", {}) : config
    ]

    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition,
    ]
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.task_config.name}-task-${var.env}"
  execution_role_arn       = var.task_config.execution_role_arn
  task_role_arn            = var.task_config.task_role_arn
  network_mode             = var.task_config.network_mode
  requires_compatibilities = var.task_config.requires_compatibilities
  cpu                      = var.task_config.cpu
  memory                   = var.task_config.memory
  container_definitions    = var.task_config.container_definitions

  lifecycle {
    ignore_changes = [
      # container_definitionをTerraformから変更する場合はコメントアウトする
      container_definitions
    ]
  }
}
