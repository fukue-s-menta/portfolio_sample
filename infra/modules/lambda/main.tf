# --- Upload Lambda ---
data "archive_file" "upload" {
  type        = "zip"
  source_file = "${path.module}/../../../../app/src/handlers/upload.py"
  output_path = "${path.module}/builds/upload.zip"
}

resource "aws_lambda_function" "upload" {
  function_name    = "${var.project_name}-upload"
  role             = var.upload_role_arn
  handler          = "upload.handler"
  runtime          = "python3.12"
  memory_size      = var.memory_size
  timeout          = var.timeout
  filename         = data.archive_file.upload.output_path
  source_code_hash = data.archive_file.upload.output_base64sha256

  environment {
    variables = {
      S3_BUCKET      = var.s3_bucket_name
      DYNAMODB_TABLE = var.dynamodb_table
    }
  }
}

# --- Resize Lambda ---
data "archive_file" "resize" {
  type        = "zip"
  source_dir  = "${path.module}/../../../../app/src/handlers"
  output_path = "${path.module}/builds/resize.zip"
}

resource "aws_lambda_function" "resize" {
  function_name    = "${var.project_name}-resize"
  role             = var.resize_role_arn
  handler          = "resize.handler"
  runtime          = "python3.12"
  memory_size      = var.memory_size
  timeout          = var.timeout
  filename         = data.archive_file.resize.output_path
  source_code_hash = data.archive_file.resize.output_base64sha256

  layers = [
    "arn:aws:lambda:ap-northeast-1:770693421928:layer:Klayers-p312-Pillow:4"
  ]

  environment {
    variables = {
      S3_BUCKET         = var.s3_bucket_name
      DYNAMODB_TABLE    = var.dynamodb_table
      CLOUDFRONT_DOMAIN = var.cloudfront_domain
    }
  }
}

resource "aws_lambda_permission" "s3_invoke_resize" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resize.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

# --- Get Lambda ---
data "archive_file" "get" {
  type        = "zip"
  source_file = "${path.module}/../../../../app/src/handlers/get_image.py"
  output_path = "${path.module}/builds/get.zip"
}

resource "aws_lambda_function" "get" {
  function_name    = "${var.project_name}-get"
  role             = var.get_role_arn
  handler          = "get_image.handler"
  runtime          = "python3.12"
  memory_size      = 256
  timeout          = 10
  filename         = data.archive_file.get.output_path
  source_code_hash = data.archive_file.get.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table
    }
  }
}

# --- Delete Lambda ---
data "archive_file" "delete" {
  type        = "zip"
  source_file = "${path.module}/../../../../app/src/handlers/delete_image.py"
  output_path = "${path.module}/builds/delete.zip"
}

resource "aws_lambda_function" "delete" {
  function_name    = "${var.project_name}-delete"
  role             = var.delete_role_arn
  handler          = "delete_image.handler"
  runtime          = "python3.12"
  memory_size      = 256
  timeout          = 10
  filename         = data.archive_file.delete.output_path
  source_code_hash = data.archive_file.delete.output_base64sha256

  environment {
    variables = {
      S3_BUCKET      = var.s3_bucket_name
      DYNAMODB_TABLE = var.dynamodb_table
    }
  }
}
