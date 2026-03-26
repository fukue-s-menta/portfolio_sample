# =============================================================================
# Serverless Image Resize API — Main Configuration
# =============================================================================

# --- S3: Image Storage ---
module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  environment  = var.environment
}

# --- DynamoDB: Image Metadata ---
module "dynamodb" {
  source       = "./modules/dynamodb"
  project_name = var.project_name
  environment  = var.environment
}

# --- IAM: Lambda Execution Roles ---
module "iam" {
  source              = "./modules/iam"
  project_name        = var.project_name
  s3_bucket_arn       = module.s3.bucket_arn
  dynamodb_table_arn  = module.dynamodb.table_arn
}

# --- Lambda: Functions ---
module "lambda" {
  source = "./modules/lambda"

  project_name    = var.project_name
  environment     = var.environment
  memory_size     = var.lambda_memory_size
  timeout         = var.lambda_timeout
  s3_bucket_name  = module.s3.bucket_name
  s3_bucket_arn   = module.s3.bucket_arn
  dynamodb_table  = module.dynamodb.table_name
  cloudfront_domain = module.cloudfront.distribution_domain_name

  upload_role_arn  = module.iam.upload_lambda_role_arn
  resize_role_arn  = module.iam.resize_lambda_role_arn
  get_role_arn     = module.iam.get_lambda_role_arn
  delete_role_arn  = module.iam.delete_lambda_role_arn
}

# --- API Gateway: REST API ---
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name         = var.project_name
  environment          = var.environment
  throttle_rate_limit  = var.api_throttle_rate_limit
  throttle_burst_limit = var.api_throttle_burst_limit
  quota_limit          = var.api_quota_limit

  upload_lambda_arn    = module.lambda.upload_function_arn
  upload_invoke_arn    = module.lambda.upload_invoke_arn
  get_lambda_arn       = module.lambda.get_function_arn
  get_invoke_arn       = module.lambda.get_invoke_arn
  delete_lambda_arn    = module.lambda.delete_function_arn
  delete_invoke_arn    = module.lambda.delete_invoke_arn
}

# --- CloudFront: CDN ---
module "cloudfront" {
  source       = "./modules/cloudfront"
  project_name = var.project_name
  s3_bucket_id = module.s3.bucket_id
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
}

# --- S3 Event Notification: Trigger Resize Lambda ---
resource "aws_s3_bucket_notification" "image_upload" {
  bucket = module.s3.bucket_id

  lambda_function {
    lambda_function_arn = module.lambda.resize_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "original/"
  }

  depends_on = [module.lambda]
}

# --- CloudWatch Alarm: Lambda Errors ---
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda error count exceeds threshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = module.lambda.resize_function_name
  }
}

# --- AWS Budgets ---
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project_name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
