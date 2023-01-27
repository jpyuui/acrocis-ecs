resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name}-standalone-task-${var.env}"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.cpu
  memory                   = var.memory
  container_definitions    = var.container_definitions

  lifecycle {
    ignore_changes = [
      # container_definitionをTerraformから変更する場合はコメントアウトする
      container_definitions
    ]
  }
}
