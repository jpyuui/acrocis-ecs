# =================
# IAM Role
# =================
resource "aws_iam_role" "this" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = [
        var.assume_identifier,
        ]
    }
  }
}


# =================
# IAM Policy
# =================
resource "aws_iam_policy" "custom" {
  name   = var.name
  policy = var.policy
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.custom.arn
}
