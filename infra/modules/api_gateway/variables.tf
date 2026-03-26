variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "throttle_rate_limit" {
  type = number
}

variable "throttle_burst_limit" {
  type = number
}

variable "quota_limit" {
  type = number
}

variable "upload_lambda_arn" {
  type = string
}

variable "upload_invoke_arn" {
  type = string
}

variable "get_lambda_arn" {
  type = string
}

variable "get_invoke_arn" {
  type = string
}

variable "delete_lambda_arn" {
  type = string
}

variable "delete_invoke_arn" {
  type = string
}
