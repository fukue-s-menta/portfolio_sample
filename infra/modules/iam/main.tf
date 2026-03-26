# --- Common: Lambda Assume Role Policy ---
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# --- Common: CloudWatch Logs Policy ---
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# =============================================================================
# Upload Lambda Role
# =============================================================================
resource "aws_iam_role" "upload_lambda" {
  name               = "${var.project_name}-upload-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "upload_lambda" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${var.s3_bucket_arn}/original/*"]
  }
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "upload_lambda" {
  name   = "upload-policy"
  role   = aws_iam_role.upload_lambda.id
  policy = data.aws_iam_policy_document.upload_lambda.json
}

resource "aws_iam_role_policy" "upload_lambda_logs" {
  name   = "cloudwatch-logs"
  role   = aws_iam_role.upload_lambda.id
  policy = data.aws_iam_policy_document.cloudwatch_logs.json
}

# =============================================================================
# Resize Lambda Role
# =============================================================================
resource "aws_iam_role" "resize_lambda" {
  name               = "${var.project_name}-resize-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "resize_lambda" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_arn}/original/*"]
  }
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${var.s3_bucket_arn}/resized/*"]
  }
  statement {
    actions   = ["dynamodb:UpdateItem"]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "resize_lambda" {
  name   = "resize-policy"
  role   = aws_iam_role.resize_lambda.id
  policy = data.aws_iam_policy_document.resize_lambda.json
}

resource "aws_iam_role_policy" "resize_lambda_logs" {
  name   = "cloudwatch-logs"
  role   = aws_iam_role.resize_lambda.id
  policy = data.aws_iam_policy_document.cloudwatch_logs.json
}

# =============================================================================
# Get Lambda Role
# =============================================================================
resource "aws_iam_role" "get_lambda" {
  name               = "${var.project_name}-get-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "get_lambda" {
  statement {
    actions   = ["dynamodb:GetItem"]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "get_lambda" {
  name   = "get-policy"
  role   = aws_iam_role.get_lambda.id
  policy = data.aws_iam_policy_document.get_lambda.json
}

resource "aws_iam_role_policy" "get_lambda_logs" {
  name   = "cloudwatch-logs"
  role   = aws_iam_role.get_lambda.id
  policy = data.aws_iam_policy_document.cloudwatch_logs.json
}

# =============================================================================
# Delete Lambda Role
# =============================================================================
resource "aws_iam_role" "delete_lambda" {
  name               = "${var.project_name}-delete-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "delete_lambda" {
  statement {
    actions   = ["s3:DeleteObject"]
    resources = [
      "${var.s3_bucket_arn}/original/*",
      "${var.s3_bucket_arn}/resized/*",
    ]
  }
  statement {
    actions   = ["dynamodb:DeleteItem", "dynamodb:GetItem"]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "delete_lambda" {
  name   = "delete-policy"
  role   = aws_iam_role.delete_lambda.id
  policy = data.aws_iam_policy_document.delete_lambda.json
}

resource "aws_iam_role_policy" "delete_lambda_logs" {
  name   = "cloudwatch-logs"
  role   = aws_iam_role.delete_lambda.id
  policy = data.aws_iam_policy_document.cloudwatch_logs.json
}
