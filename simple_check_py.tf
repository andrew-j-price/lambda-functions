data "archive_file" "simple_check_py" {
  type        = "zip"
  source_dir  = "${path.module}/simple_check_py"
  output_path = "${path.module}/simple_check_py.zip"
}

resource "aws_lambda_function" "simple_check_py" {
  filename         = data.archive_file.simple_check_py.output_path
  function_name    = "simple_check_py"
  role             = aws_iam_role.lincas_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 60
  source_code_hash = filebase64sha256(data.archive_file.simple_check_py.output_path)
  /* NOTES:
     vpc_config is optional, internet bound traffic does not have to be in VPC, but VPC bound traffic must be in private subnet
     For IPv4 outbound traffic, VPC needs NAT Gateway or NAT Instance
     For IPv6 outbound traffic, tried egress-only-gateway but would not work for Lambda functions however did work on EC2 instances in the same private subnet
  */
  /*
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_default_secgroup.id]
  }
  */
  tags = merge(var.common_tags, {
    func = "simple_check_py"
  })
  depends_on = [aws_cloudwatch_log_group.simple_check_py]
}

resource "aws_cloudwatch_log_group" "simple_check_py" {
  name              = "/aws/lambda/simple_check_py"
  retention_in_days = 3
}

// TRIGGER: EventBridge (CloudWatch Events)
resource "aws_cloudwatch_event_target" "simple_check_py" {
  rule = aws_cloudwatch_event_rule.default_schedule.name
  arn  = aws_lambda_function.simple_check_py.arn
}

// TRIGGER: EventBridge (CloudWatch Events)
resource "aws_lambda_permission" "simple_check_py" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.simple_check_py.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.default_schedule.arn
}

// SNS Integration
resource "aws_cloudwatch_metric_alarm" "simple_check_py_failure" {
  alarm_name                = "simple_check_py_failure"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  threshold                 = 1
  alarm_actions             = [aws_sns_topic.notifications_topic.arn]
  insufficient_data_actions = []
  metric_query {
    id    = "errors"
    label = "Errors"
    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"
      period      = "600"
      stat        = "Sum"
      unit        = "Count"
      dimensions = {
        FunctionName = aws_lambda_function.simple_check_py.function_name
      }
    }
    return_data = true
  }
}
