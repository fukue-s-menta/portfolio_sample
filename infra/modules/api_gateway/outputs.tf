output "api_endpoint" {
  value = "${aws_api_gateway_stage.main.invoke_url}"
}

output "api_key" {
  value     = aws_api_gateway_api_key.main.value
  sensitive = true
}
