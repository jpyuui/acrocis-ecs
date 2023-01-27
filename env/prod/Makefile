SHELL=/bin/bash

.PHONY: $(shell egrep -oh ^[a-zA-Z0-9][a-zA-Z0-9_-]+: $(MAKEFILE_LIST) | sed 's/://')

fmt:
	terraform fmt -recursive
	terraform fmt -check

# ECRやSSMパラメータストアなど、事前に作成が必要&作成後手作業で追加の動作を要するmoduleを個別に作成する
plan-initial-set-up-prod: fmt
	terraform plan -var-file prod.tfvars \
	-target=module.aws_access_key_id -target=module.aws_secret_access_key \
	-target=module.db_username -target=module.db_password \
	-target=module.shopify_shop_url -target=module.shopify_api_key -target=module.shopify_api_secret \
	-target=module.shopify_shop_url_for_subscriber -target=module.shopify_access_token_for_subscriber -target=module.shopify_api_key_for_subscriber -target=module.shopify_api_secret_for_subscriber \
	-target=module.hubspot_api_key -target=module.hubspot_access_token \
	-target=module.token_cloudfront_header_value_for_alb

# ECRやSSMパラメータストアなど、事前に作成が必要&作成後手作業で追加の動作を要するmoduleを個別に作成する
apply-initial-set-up-prod: fmt
	terraform apply -var-file prod.tfvars \
	-target=module.ecr_for_web -target=module.ecr_for_subscriber \
	-target=module.aws_access_key_id -target=module.aws_secret_access_key \
	-target=module.db_username -target=module.db_password \
	-target=module.shopify_shop_url -target=module.shopify_api_key -target=module.shopify_api_secret \
	-target=module.shopify_shop_url_for_subscriber -target=module.shopify_access_token_for_subscriber -target=module.shopify_api_key_for_subscriber -target=module.shopify_api_secret_for_subscriber \
	-target=module.hubspot_api_key -target=module.hubspot_access_token \
	-target=module.token_cloudfront_header_value_for_alb

plan-prod: fmt
	terraform plan -var-file prod.tfvars

plan-prod-verbose: fmt
	TF_LOG=debug terraform plan -var-file prod.tfvars

apply-prod: fmt
	terraform apply -var-file prod.tfvars
