locals {
  env_prefix            = "/${var.env}"
  web_app_prefix        = "web"
  subscriber_app_prefix = "subscriber"
  aws_prefix            = "aws"
  database_prefix       = "db"
  shopify_prefix        = "shopify"
  hubspot_prefix        = "hubspot"
  token_prefix          = "token"
}


# =================
# AWS
# =================
module "aws_access_key_id" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.aws_prefix}/access_key_id"
  description = "access key id for aws"
}

module "aws_secret_access_key" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.aws_prefix}/secret_access_key"
  description = "secret access key for aws"
}


# =================
# Database
# =================
module "db_username" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.database_prefix}/username"
  description = "username for rds cluster"
}

module "db_password" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.database_prefix}/password"
  description = "password for rds cluster"
}


# =================
# Shopify
# =================
module "shopify_shop_url" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.shopify_prefix}/shop_url"
  description = "shop_url for shopify"
}

module "shopify_api_key" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.shopify_prefix}/api_key"
  description = "api key for shopify"
}

module "shopify_api_secret" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.shopify_prefix}/api_secret"
  description = "api secret for shopify"
}

module "shopify_shop_url_for_subscriber" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.subscriber_app_prefix}/${local.shopify_prefix}/shop_url"
  description = "shop_url for shopify"
}

module "shopify_access_token_for_subscriber" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.subscriber_app_prefix}/${local.shopify_prefix}/access_token"
  description = "access_token for shopify"
}

module "shopify_api_key_for_subscriber" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.subscriber_app_prefix}/${local.shopify_prefix}/api_key"
  description = "api key for shopify"
}

module "shopify_api_secret_for_subscriber" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.subscriber_app_prefix}/${local.shopify_prefix}/api_secret"
  description = "api secret for shopify"
}


# =================
# Hubspot
# =================
module "hubspot_api_key" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.hubspot_prefix}/api_key"
  description = "api key for hubspot"
}

module "hubspot_access_token" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.hubspot_prefix}/access_token"
  description = "access_token for hubspot"
}


# =================
# Token
# =================
module "token_cloudfront_header_value_for_alb" {
  source      = "../../modules/secret_param_store"
  name        = "${local.env_prefix}/${local.token_prefix}/cloudfront_header_value_for_alb"
  description = "cloudfront header value for alb"
}
