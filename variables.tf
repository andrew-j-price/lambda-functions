variable "aws_region" {
  default = "us-east-2"
}

variable "common_tags" {
  type    = map(any)
  default = {}
}

variable "lambda_role_arn" {
  type        = list(string)
  description = "ARN of managed policy that needs to be attached to role created for lambda"
  default     = ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
}

variable "sns_emails" {
  type    = list(string)
  default = ["somebody@example.com"]
}

variable "sns_webhook_protocol" {
  type    = string
  default = "https"
}

variable "sns_webhook_url" {
  type    = string
  default = "https://example.com/notify/slack"
}

variable "subnet_ids" {
  type    = list(any)
  default = null
}

variable "notifications_topic" {
  type    = string
  default = "default_topic"
}

variable "vpc_id" {
  type    = string
  default = null
}
