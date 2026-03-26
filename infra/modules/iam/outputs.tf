output "upload_lambda_role_arn" {
  value = aws_iam_role.upload_lambda.arn
}

output "resize_lambda_role_arn" {
  value = aws_iam_role.resize_lambda.arn
}

output "get_lambda_role_arn" {
  value = aws_iam_role.get_lambda.arn
}

output "delete_lambda_role_arn" {
  value = aws_iam_role.delete_lambda.arn
}
