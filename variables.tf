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

variable "subnet_ids" {
  type    = list(any)
  default = null
}
variable "vpc_id" {
  type    = string
  default = null
}
