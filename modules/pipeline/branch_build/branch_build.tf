# ============================
# Code Build for By Branch
# ============================
resource "aws_codebuild_project" "by_branch" {
  name         = "${var.name}-build-by-branch-${var.env}"
  description  = "for ${var.name}-${var.env}"
  service_role = var.code_build_iam_role_arn

  source {
    type                = "GITHUB"
    location            = var.repository_url
    git_clone_depth     = 1
    report_build_status = true
    buildspec           = "buildspec.yml"
  }

  artifacts {
    type = "NO_ARTIFACTS"
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

resource "aws_codebuild_webhook" "this" {
  project_name = aws_codebuild_project.by_branch.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      exclude_matched_pattern = true
      type                    = "HEAD_REF"
      # Pipelineで動作するCodeBuildと責務分離するために、master,releaseブランチはbuildしない
      # 不要なBuildを防ぐため、terraformから始まるブランチはbuildしない
      pattern = "^refs/heads/master$|^refs/heads/release$|^refs/heads/terraform*"
    }
  }
}
