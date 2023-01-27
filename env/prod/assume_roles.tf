# ===================
# ECS Application Web
# ===================
data "aws_iam_policy_document" "task_execution_policy_for_ecs_web" {
  statement {
    effect = "Allow"

    actions = [
      # ECR
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",

      # Log
      "logs:CreateLogStream",
      "logs:PutLogEvents",

      # ssm parameter store
      "ssm:Describe*",
      "ssm:Get*",
      "ssm:List*"
    ]

    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/*",
    ]
  }
}

module "task_execution_role_for_web" {
  source            = "../../modules/iam_role/custom_role"
  name              = "task_execution_role_for_ecs_web_app"
  assume_identifier = "ecs-tasks.amazonaws.com"
  policy            = data.aws_iam_policy_document.task_execution_policy_for_ecs_web.json
}

data "aws_iam_policy_document" "task_role_policy_for_ecs_web" {
  statement {
    effect = "Allow"

    actions = [
      # Exec
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",

      # Log
      "firehose:PutRecordBatch",
      "logs:DescribeLogStreams",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }
}

module "task_role_for_web" {
  source            = "../../modules/iam_role/custom_role"
  name              = "task_role_for_ecs_web_app"
  assume_identifier = "ecs-tasks.amazonaws.com"
  policy            = data.aws_iam_policy_document.task_role_policy_for_ecs_web.json
}


# ===========================
# ECS Application Subscriber
# ===========================
data "aws_iam_policy_document" "task_execution_policy_for_ecs_subscriber" {
  statement {
    effect = "Allow"

    actions = [
      # ECR
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",

      # Log
      "logs:CreateLogStream",
      "logs:PutLogEvents",

      # ssm parameter store
      "ssm:Describe*",
      "ssm:Get*",
      "ssm:List*"
    ]

    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/*",
    ]
  }
}

module "task_execution_role_for_subscriber" {
  source            = "../../modules/iam_role/custom_role"
  name              = "task_execution_role_for_ecs_subscriber_app"
  assume_identifier = "ecs-tasks.amazonaws.com"
  policy            = data.aws_iam_policy_document.task_execution_policy_for_ecs_subscriber.json
}

data "aws_iam_policy_document" "task_role_policy_for_ecs_subscriber" {
  statement {
    effect = "Allow"

    actions = [
      # Exec
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",

      # SQS
      "sqs:*",

      # Log
      "firehose:PutRecordBatch",
      "logs:DescribeLogStreams",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }
}

module "task_role_for_subscriber" {
  source            = "../../modules/iam_role/custom_role"
  name              = "task_role_for_ecs_subscriber_app"
  assume_identifier = "ecs-tasks.amazonaws.com"
  policy            = data.aws_iam_policy_document.task_role_policy_for_ecs_subscriber.json
}


# ===========================
# ECS Application Migrate
# ===========================
data "aws_iam_policy_document" "task_execution_policy_for_ecs_migrate" {
  statement {
    effect = "Allow"

    actions = [
      # ECR
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",

      # Log
      "logs:CreateLogStream",
      "logs:PutLogEvents",

      # ssm parameter store
      "ssm:Describe*",
      "ssm:Get*",
      "ssm:List*"
    ]

    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/*",
    ]
  }
}

module "task_execution_role_for_migrate" {
  source            = "../../modules/iam_role/custom_role"
  name              = "task_execution_role_for_ecs_migrate_app"
  assume_identifier = "ecs-tasks.amazonaws.com"
  policy            = data.aws_iam_policy_document.task_execution_policy_for_ecs_migrate.json
}

data "aws_iam_policy_document" "task_role_policy_for_ecs_migrate" {
  statement {
    effect = "Allow"

    actions = [
      # Exec
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",

      # Log
      "firehose:PutRecordBatch",
      "logs:DescribeLogStreams",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }
}

module "task_role_for_migrate" {
  source            = "../../modules/iam_role/custom_role"
  name              = "task_role_for_ecs_migrate_app"
  assume_identifier = "ecs-tasks.amazonaws.com"
  policy            = data.aws_iam_policy_document.task_role_policy_for_ecs_migrate.json
}


# =============================
# CloudWatchLogs for ErrorLogs
# =============================
data "aws_iam_policy_document" "for_cloudwatch_to_firehose" {
  statement {
    effect = "Allow"

    actions = [
      "firehose:*"
    ]

    resources = [
      "*",
    ]
  }
}

module "iam_role_for_cloudwatch_to_firehose" {
  source            = "../../modules/iam_role/custom_role"
  name              = "for_cloudwatch_to_firehose"
  assume_identifier = "logs.ap-northeast-1.amazonaws.com"
  policy            = data.aws_iam_policy_document.for_cloudwatch_to_firehose.json
}


# =============================
# Lambda for SNS
# =============================
data "aws_iam_policy_document" "for_error_notifier" {
  statement {
    effect = "Allow"

    actions = [
      "SNS:Publish",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }
}

module "iam_role_for_lambda_for_error_notifier" {
  source            = "../../modules/iam_role/custom_role"
  name              = "for_lambda_for_error_notifier"
  assume_identifier = "lambda.amazonaws.com"
  policy            = data.aws_iam_policy_document.for_error_notifier.json
}


# ===========================
# Kinesis Firehose
# ===========================
data "aws_iam_policy_document" "for_firehose" {
  statement {
    effect = "Allow"

    actions = [
      # S3 Log Bucket
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",

      # Lambda Data Processer
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration",

      # Log
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }
}

module "iam_role_for_firehose" {
  source            = "../../modules/iam_role/custom_role"
  name              = "iam_role_for_firehose"
  assume_identifier = "firehose.amazonaws.com"
  policy            = data.aws_iam_policy_document.for_firehose.json
}

data "aws_iam_policy_document" "for_lambda_data_processer" {
  statement {
    effect = "Allow"

    actions = [
      "firehose:PutRecordBatch",
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:ListShards",
      "kinesis:ListStreams",
      "kinesis:SubscribeToShard",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }
}


module "iam_role_for_lambda_data_processer" {
  source            = "../../modules/iam_role/custom_role"
  name              = "iam_role_for_lambda_data_processer"
  assume_identifier = "lambda.amazonaws.com"
  policy            = data.aws_iam_policy_document.for_lambda_data_processer.json
}


# ===========================
# Code Pipeline / Build
# ===========================
data "aws_iam_policy_document" "for_code_pipeline" {
  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecr:DescribeImages",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "codestar-connections:UseConnection"
    ]

    resources = [
      "*",
    ]
  }
}


module "iam_role_for_code_pipeline" {
  source            = "../../modules/iam_role/custom_role"
  name              = "iam_role_for_code_pipeline"
  assume_identifier = "codepipeline.amazonaws.com"
  policy            = data.aws_iam_policy_document.for_code_pipeline.json
}

data "aws_iam_policy_document" "for_code_build" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages",
      "ecr:*",
      "codestar-connections:UseConnection"
    ]

    resources = [
      "*",
    ]
  }
}


module "iam_role_for_code_build" {
  source            = "../../modules/iam_role/custom_role"
  name              = "iam_role_for_code_build"
  assume_identifier = "codebuild.amazonaws.com"
  policy            = data.aws_iam_policy_document.for_code_build.json
}

data "aws_iam_policy_document" "for_migrate_code_build" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages",
      "ssm:Describe*",
      "ssm:Get*",
      "ssm:List*",
      "ecr:*",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "codestar-connections:UseConnection"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterfacePermission",
    ]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "ec2:Subnet"
      values   = ["arn:aws:ec2:*:*:subnet/*"]
    }

    resources = [
      "*",
    ]
  }
}


module "iam_role_for_migrate_code_build" {
  source            = "../../modules/iam_role/custom_role"
  name              = "iam_role_for_migrate_code_build"
  assume_identifier = "codebuild.amazonaws.com"
  policy            = data.aws_iam_policy_document.for_migrate_code_build.json
}

data "aws_iam_policy_document" "for_ecs_autoscaling" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DeleteAlarms"
    ]

    resources = [
      "*",
    ]
  }
}


module "iam_role_for_ecs_autoscaling" {
  source            = "../../modules/iam_role/custom_role"
  name              = "iam_role_for_ecs_autoscaling"
  assume_identifier = "application-autoscaling.amazonaws.com"
  policy            = data.aws_iam_policy_document.for_ecs_autoscaling.json
}


