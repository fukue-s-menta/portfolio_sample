output "upload_function_arn" {
  value = aws_lambda_function.upload.arn
}

output "upload_invoke_arn" {
  value = aws_lambda_function.upload.invoke_arn
}

output "resize_function_arn" {
  value = aws_lambda_function.resize.arn
}

output "resize_function_name" {
  value = aws_lambda_function.resize.function_name
}

output "get_function_arn" {
  value = aws_lambda_function.get.arn
}

output "get_invoke_arn" {
  value = aws_lambda_function.get.invoke_arn
}

output "delete_function_arn" {
  value = aws_lambda_function.delete.arn
}

output "delete_invoke_arn" {
  value = aws_lambda_function.delete.invoke_arn
}
