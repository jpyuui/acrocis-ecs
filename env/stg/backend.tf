terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.17.0"
    }
  }

  backend "s3" {
    bucket         = "xxx-tf-state-stg"
    region         = "ap-northeast-1"
    key            = "terraform.tfstate"
    encrypt        = true
    dynamodb_table = "xxx_tfstate_lock_stg"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.default_tags
  }
}

resource "aws_dynamodb_table" "this" {
  name           = "xxx_tfstate_lock_stg"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
