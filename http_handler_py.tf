data "archive_file" "http_handler_py" {
  type        = "zip"
  source_dir  = "${path.module}/http_handler_py"
  output_path = "${path.module}/http_handler_py.zip"
}

resource "aws_lambda_function" "http_handler_py" {
  filename         = data.archive_file.http_handler_py.output_path
  function_name    = "http_handler_py"
  role             = aws_iam_role.lincas_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 60
  source_code_hash = filebase64sha256(data.archive_file.http_handler_py.output_path)
  /* NOTES:
     vpc_config is optional, internet bound traffic does not have to be in VPC, but VPC bound traffic must be in private subnet
     For IPv4 outbound traffic, VPC needs NAT Gateway or NAT Instance
     For IPv6 outbound traffic, tried egress-only-gateway but would not work for Lambda functions however did work on EC2 instances in the same private subnet
  */
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_default_secgroup.id]
  }
  tags = merge(var.common_tags, {
    func = "http_handler_py"
  })
  depends_on = [aws_cloudwatch_log_group.http_handler_py]
}

resource "aws_cloudwatch_log_group" "http_handler_py" {
  name              = "/aws/lambda/http_handler_py"
  retention_in_days = 3
}

// NOTE: not necessary for all functions
resource "aws_cloudwatch_event_target" "http_handler_py" {
  rule = aws_cloudwatch_event_rule.default_schedule.name
  arn  = aws_lambda_function.http_handler_py.arn
}

// NOTE: not necessary for all functions
resource "aws_lambda_permission" "http_handler_py" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.http_handler_py.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.default_schedule.arn
}
