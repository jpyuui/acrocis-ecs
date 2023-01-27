# =================
# Code Pipeline
# =================
resource "aws_codepipeline" "this" {
  name     = "${var.name}-pipeline-${var.env}"
  role_arn = var.code_pipeline_iam_role_arn

  artifact_store {
    location = aws_s3_bucket.this.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn        = var.connection_arn
        FullRepositoryId     = "${var.repository_owner_name}/${var.repository_name}"
        BranchName           = var.trigger_branch_name
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 2
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.this.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["BuildArtifact"]
      version         = "1"

      configuration = {
        ClusterName = var.deploy_cluster_name
        ServiceName = var.deploy_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}


# ============================
# Code Build for App Pipeline
# ============================
resource "aws_codebuild_project" "this" {
  name         = "${var.name}-build-${var.env}"
  description  = "for ${var.name}-${var.env}"
  service_role = var.code_build_iam_role_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec_file_name
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    privileged_mode = true

    environment_variable {
      name  = "DOCKER_BUILDKIT"
      value = "1"
    }
  }
}


# =================
# S3 ArtifactStore
# =================
resource "aws_s3_bucket" "this" {
  bucket        = "${var.name}-code-artifact-${var.env}"
  force_destroy = false
}

resource "aws_s3_bucket_acl" "private" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
