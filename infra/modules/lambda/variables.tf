variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "memory_size" {
  type = number
}

variable "timeout" {
  type = number
}

variable "s3_bucket_name" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "dynamodb_table" {
  type = string
}

variable "cloudfront_domain" {
  type = string
}

variable "upload_role_arn" {
  type = string
}

variable "resize_role_arn" {
  type = string
}

variable "get_role_arn" {
  type = string
}

variable "delete_role_arn" {
  type = string
}
