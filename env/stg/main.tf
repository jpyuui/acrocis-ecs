# =================
# AccountData
# =================
data "aws_caller_identity" "current" {}


# =================
# Network
# =================
module "network" {
  source = "../../modules/network"
  cidr   = "10.0.0.0/16"
  public_subnets = [
    {
      name = "pub1"
      cidr = "10.0.1.0/24"
      az   = "ap-northeast-1a"
    },
    {
      name = "pub2"
      cidr = "10.0.2.0/24"
      az   = "ap-northeast-1c"
    },
  ]
  private_subnets = [
    {
      name = "pri1"
      cidr = "10.0.65.0/24"
      az   = "ap-northeast-1a"
    },
    {
      name = "pri2"
      cidr = "10.0.66.0/24"
      az   = "ap-northeast-1c"
    },
  ]
}


# =================
# ALB
# =================
data "aws_ssm_parameter" "cloudfront_header_value_for_alb" {
  name            = module.token_cloudfront_header_value_for_alb.name
  with_decryption = true
}

module "http_sg" {
  source = "../../modules/sg"
  name   = "${var.service_name}_http_sg_${var.env}"
  vpc_id = module.network.vpc_id
  ingress_rules = {
    http = {
      to_port   = 80
      from_port = 80
      protocol  = "tcp"
      allow_cidrs = [
        "0.0.0.0/0",
      ]
    }
  }
}

module "alb" {
  source     = "../../modules/alb"
  name       = var.service_name
  env        = var.env
  vpc_id     = module.network.vpc_id
  subnet_ids = values(module.network.public_subnets)[*].id
  security_group_ids = [
    module.http_sg.id,
  ]
  target_groups = {
    for_web = {
      name_prefix          = "forweb"
      target_type          = "ip"
      port                 = 80
      protocol             = "HTTP"
      deregistration_delay = 300
      health_check_config = {
        path = "/health"
      }
    }
  }
  listeners = {
    http = {
      port     = "80"
      protocol = "HTTP"
      rules = {
        forward = {
          type     = "forward"
          priority = 100
          forward_config = {
            target_group_name = "for_web"
          }
          conditions = {
            path_patterns = ["/*"]
          }
        }
        forbidden = {
          type     = "fixed-response"
          priority = 200
          fixed_response_config = {
            message_body = "Forbidden"
            status_code  = 403
            content_type = "text/plain"
          }
          conditions = {
            path_patterns = ["/*"]
          }
        }
      }
    }
  }
}


# ===========================
# RDS Cluster Main
# ===========================
locals {
  main_database_port = 3306
}

module "database_sg" {
  source = "../../modules/sg"
  name   = "${var.service_name}_database_sg_${var.env}"
  vpc_id = module.network.vpc_id
  ingress_rules = {
    http = {
      to_port   = local.main_database_port
      from_port = local.main_database_port
      protocol  = "tcp"
      allow_cidrs = [
        module.network.vpc_cidr,
      ]
    }
  }
}

module "rds_cluster_main" {
  source               = "../../modules/rds"
  name                 = var.service_name
  env                  = var.env
  family               = "aurora-mysql5.7"
  engine               = "aurora-mysql"
  engine_version       = "5.7.mysql_aurora.2.09.2"
  port                 = local.main_database_port
  timezone             = "Asia/Tokyo"
  char_code            = "utf8mb4"
  instance_names       = ["0"]
  instance_class       = "db.t3.small"
  security_group_id    = module.database_sg.id
  subnet_ids           = values(module.network.private_subnets)[*].id
  availability_zones   = values(module.network.private_subnets)[*].availability_zone
  ssm_db_username_name = module.db_username.name
  ssm_db_password_name = module.db_password.name
}


# =================
# ElasticCache
# =================
module "elasticache_sg" {
  source = "../../modules/sg"
  name   = "sg_for_elasticache_${var.env}"
  vpc_id = module.network.vpc_id
  ingress_rules = {
    for_redis = {
      to_port     = 6379
      from_port   = 6379
      protocol    = "tcp"
      allow_cidrs = [module.network.vpc_cidr]
    }
  }
  egress_rules = {
    outbound = {
      to_port     = 0
      from_port   = 0
      protocol    = "-1"
      allow_cidrs = ["0.0.0.0/0"]
    }
  }
}

module "elasticache" {
  source             = "../../modules/elasticache"
  env                = var.env
  num_cache_groups   = 1
  num_cache_replicas = 1
  name               = var.service_name
  node_type          = "cache.t4g.micro"
  vpc_id             = module.network.vpc_id
  subnet_ids         = values(module.network.private_subnets)[*].id
  sg_id              = module.elasticache_sg.id
  cidr_blocks        = module.network.vpc_cidr
}


# ===================
# CloudFront for Web
# ===================
module "cloudfront_for_web" {
  source      = "../../modules/cloudfront"
  domain_name = module.alb.dns_name
  origin_id   = module.alb.id
  custom_origin_headers = {
    for_alb = {
      name  = "x-for-alb-header"
      value = data.aws_ssm_parameter.cloudfront_header_value_for_alb.value
    }
  }
}


# ====================
# ECS Cluster
# ====================
resource "aws_ecs_cluster" "main" {
  name = "${var.service_name}-cluster-${var.env}"
}


# ====================
# ECS Application Web
# ====================
locals {
  ecr_repository_uri             = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  ecr_repository_name_web        = "xxx-dxpj-web"
  ecr_repository_name_subscriber = "xxx-dxpj-subscriber"
}

module "logger_for_web" {
  source                              = "../../modules/ecs/log_report"
  producer_name                       = "web"
  env                                 = var.env
  region                              = var.region
  cloudwatch_to_firehose_iam_role_arn = module.iam_role_for_cloudwatch_to_firehose.arn
  firehose_iam_role_arn               = module.iam_role_for_firehose.arn
  data_processer_lambda_iam_role_arn  = module.iam_role_for_lambda_data_processer.arn
  error_notifier_lambda_iam_role_arn  = module.iam_role_for_lambda_for_error_notifier.arn
  notification_emails                 = var.developper_emails
}

module "pipeline_for_web" {
  source                       = "../../modules/pipeline/deploy"
  name                         = "web"
  env                          = var.env
  region                       = var.region
  connection_arn               = var.codestar_connection_arn
  repository_owner_name        = "framgia"
  repository_name              = local.ecr_repository_name_web
  trigger_branch_name          = "master"
  buildspec_file_name          = "buildspec.stg.yml"
  deploy_cluster_name          = aws_ecs_cluster.main.name
  deploy_service_name          = module.ecs_web_app.service_name
  notification_emails          = var.developper_emails
  code_pipeline_iam_role_arn   = module.iam_role_for_code_pipeline.arn
  code_build_iam_role_arn      = module.iam_role_for_code_build.arn
  notifier_lambda_iam_role_arn = module.iam_role_for_lambda_for_error_notifier.arn
}

module "branch_builder_for_web" {
  source                  = "../../modules/pipeline/branch_build"
  name                    = "web"
  env                     = var.env
  repository_url          = var.web_app_repository_url
  code_build_iam_role_arn = module.iam_role_for_code_build.arn
}

module "web_autoscaling" {
  source       = "../../modules/autoscaling"
  cluster      = aws_ecs_cluster.main.name
  service      = "web-service-${var.env}"
  role_arn     = module.iam_role_for_ecs_autoscaling.arn
  max_capacity = 4
  min_capacity = 1
}

module "ecs_web_app" {
  source      = "../../modules/ecs/application"
  cluster_id  = aws_ecs_cluster.main.id
  name        = var.service_name
  env         = var.env
  launch_type = "FARGATE"
  service_config = {
    name                   = "web"
    desired_count          = 1
    enable_execute_command = true
    network_config = {
      default = {
        assign_public_ip = true
        security_group_ids = [
          module.http_sg.id,
        ]
        subnet_ids = values(module.network.private_subnets)[*].id
      }
    }
    load_balancer_config = {
      default = {
        container_name   = "web"
        container_port   = 80
        target_group_arn = module.alb.target_groups["for_web"].arn
      }
    }
  }
  task_config = {
    name                     = "web"
    execution_role_arn       = module.task_execution_role_for_web.arn
    task_role_arn            = module.task_role_for_web.arn
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    cpu                      = "256"
    memory                   = "512"
    container_definitions = templatefile(
      "./applications/ecs_containers/web.json",
      {
        image_uri                    = "${local.ecr_repository_uri}/${local.ecr_repository_name_web}:master"
        log_router_image_uri         = "${module.logger_for_web.fluentbit_image_uri}:latest"
        app_port                     = 80
        region                       = var.region
        ssm_shopify_shop_url         = module.shopify_shop_url.arn
        ssm_shopify_api_key          = module.shopify_api_key.arn
        ssm_shopify_api_secret       = module.shopify_api_secret.arn
        ssm_db_username              = module.db_username.arn
        ssm_db_password              = module.db_password.arn
        database_host                = module.rds_cluster_main.host
        database_name                = module.rds_cluster_main.name
        static_hosting_url           = "https://${module.cloudfront_for_web.domain_name}"
        error_log_group_name         = module.logger_for_web.error_log_group_name
        log_container_log_group_name = module.logger_for_web.logger_log_group_name
        all_log_delivery_stream      = module.logger_for_web.all_log_delivery_stream
      }
    )
  }
}


# ===========================
# ECS Application Subscriber
# ===========================
module "logger_for_subscriber" {
  source                              = "../../modules/ecs/log_report"
  producer_name                       = "subscriber"
  env                                 = var.env
  region                              = var.region
  cloudwatch_to_firehose_iam_role_arn = module.iam_role_for_cloudwatch_to_firehose.arn
  firehose_iam_role_arn               = module.iam_role_for_firehose.arn
  data_processer_lambda_iam_role_arn  = module.iam_role_for_lambda_data_processer.arn
  error_notifier_lambda_iam_role_arn  = module.iam_role_for_lambda_for_error_notifier.arn
  notification_emails                 = var.developper_emails
}

module "pipeline_for_subscriber" {
  source                       = "../../modules/pipeline/deploy"
  name                         = "subscriber"
  env                          = var.env
  region                       = var.region
  connection_arn               = var.codestar_connection_arn
  repository_owner_name        = "framgia"
  repository_name              = local.ecr_repository_name_subscriber
  trigger_branch_name          = "master"
  buildspec_file_name          = "buildspec.stg.yml"
  deploy_cluster_name          = aws_ecs_cluster.main.name
  deploy_service_name          = module.ecs_subscriber_app.service_name
  notification_emails          = var.developper_emails
  code_pipeline_iam_role_arn   = module.iam_role_for_code_pipeline.arn
  code_build_iam_role_arn      = module.iam_role_for_code_build.arn
  notifier_lambda_iam_role_arn = module.iam_role_for_lambda_for_error_notifier.arn
}

module "branch_builder_for_subscriber" {
  source                  = "../../modules/pipeline/branch_build"
  name                    = "subscriber"
  env                     = var.env
  repository_url          = var.subscriber_app_repository_url
  code_build_iam_role_arn = module.iam_role_for_code_build.arn
}

module "subscriber_autoscaling" {
  source       = "../../modules/autoscaling"
  cluster      = aws_ecs_cluster.main.name
  service      = "subscriber-service-${var.env}"
  role_arn     = module.iam_role_for_ecs_autoscaling.arn
  max_capacity = 4
  min_capacity = 1
}

module "ecs_subscriber_app" {
  source      = "../../modules/ecs/application"
  cluster_id  = aws_ecs_cluster.main.id
  name        = var.service_name
  env         = var.env
  launch_type = "FARGATE"
  service_config = {
    name                   = "subscriber"
    desired_count          = 1
    enable_execute_command = true
    network_config = {
      default = {
        assign_public_ip = true
        security_group_ids = [
          module.http_sg.id,
        ]
        subnet_ids = values(module.network.private_subnets)[*].id
      }
    }
  }
  task_config = {
    name                     = "subscriber"
    execution_role_arn       = module.task_execution_role_for_subscriber.arn
    task_role_arn            = module.task_role_for_subscriber.arn
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    cpu                      = "256"
    memory                   = "512"
    container_definitions = templatefile(
      "./applications/ecs_containers/subscriber.json",
      {
        image_uri                    = "${local.ecr_repository_uri}/${local.ecr_repository_name_subscriber}:master"
        log_router_image_uri         = "${module.logger_for_subscriber.fluentbit_image_uri}:latest"
        env                          = var.env
        region                       = var.region
        app_port                     = 80
        ssm_aws_access_key_id        = module.aws_access_key_id.arn
        ssm_aws_secret_access_key    = module.aws_secret_access_key.arn
        ssm_hubspot_api_key          = module.hubspot_api_key.arn
        ssm_hubspot_access_token     = module.hubspot_access_token.arn
        ssm_shopify_shop_url         = module.shopify_shop_url_for_subscriber.arn
        ssm_shopify_access_token     = module.shopify_access_token_for_subscriber.arn
        ssm_shopify_api_key          = module.shopify_api_key_for_subscriber.arn
        ssm_shopify_secret_key       = module.shopify_api_secret_for_subscriber.arn
        ssm_db_username              = module.db_username.arn
        ssm_db_password              = module.db_password.arn
        database_host                = module.rds_cluster_main.host
        database_name                = module.rds_cluster_main.name
        sqs_url                      = module.sqs.url
        redis_url                    = "redis://${module.elasticache.endpoint}:${module.elasticache.port}"
        error_log_group_name         = module.logger_for_subscriber.error_log_group_name
        log_container_log_group_name = module.logger_for_subscriber.logger_log_group_name
        all_log_delivery_stream      = module.logger_for_subscriber.all_log_delivery_stream
      }
    )
  }

  depends_on = [
    module.rds_cluster_main,
    module.elasticache,
  ]
}


# ===========================
# ECS StandAloneTask Migrate
# ===========================
resource "aws_cloudwatch_log_group" "for_migrate_task" {
  name = "/aws/ecs/task/migrate-${var.env}"
}

module "ecs_migrate_task" {
  source                   = "../../modules/ecs/standalone"
  name                     = "migrate"
  env                      = var.env
  execution_role_arn       = module.task_execution_role_for_migrate.arn
  task_role_arn            = module.task_role_for_migrate.arn
  launch_type              = "FARGATE"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  container_definitions = templatefile(
    "./applications/ecs_containers/migrate.json",
    {
      image_uri                 = "${local.ecr_repository_uri}/${local.ecr_repository_name_subscriber}:master" # migrateはsubscriberのimageに内包
      app_port                  = 80
      sqs_url                   = module.sqs.url
      database_host             = module.rds_cluster_main.host
      database_name             = module.rds_cluster_main.name
      ssm_aws_access_key_id     = module.aws_access_key_id.arn
      ssm_aws_secret_access_key = module.aws_secret_access_key.arn
      ssm_hubspot_api_key       = module.hubspot_api_key.arn
      ssm_db_username           = module.db_username.arn
      ssm_db_password           = module.db_password.arn
      region                    = var.region
      log_group_name            = aws_cloudwatch_log_group.for_migrate_task.name
    }
  )

  depends_on = [
    module.rds_cluster_main,
  ]
}


# =================
# SQS
# =================
module "sqs" {
  source = "../../modules/sqs"
  env    = var.env
}
