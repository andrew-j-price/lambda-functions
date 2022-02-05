data "archive_file" "pass_fail_py" {
  type        = "zip"
  source_dir  = "${path.module}/../pass_fail_py"
  output_path = "${path.module}/pass_fail_py.zip"
}

resource "aws_lambda_function" "pass_fail_py" {
  filename         = data.archive_file.pass_fail_py.output_path
  function_name    = "pass_fail_py"
  role             = aws_iam_role.lincas_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 60
  source_code_hash = filebase64sha256(data.archive_file.pass_fail_py.output_path)
  tags = merge(var.common_tags, {
    func = "pass_fail_py"
  })
  depends_on = [aws_cloudwatch_log_group.pass_fail_py]
}

resource "aws_cloudwatch_log_group" "pass_fail_py" {
  name              = "/aws/lambda/pass_fail_py"
  retention_in_days = 3
}

// TRIGGER: EventBridge (CloudWatch Events)
resource "aws_cloudwatch_event_target" "pass_fail_py" {
  rule = aws_cloudwatch_event_rule.default_schedule.name
  arn  = aws_lambda_function.pass_fail_py.arn
}

// TRIGGER: EventBridge (CloudWatch Events)
resource "aws_lambda_permission" "pass_fail_py" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pass_fail_py.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.default_schedule.arn
}

// Lambda Function failire - SNS Integration
resource "aws_cloudwatch_metric_alarm" "pass_fail_py_failure" {
  alarm_name                = "pass_fail_py_failure"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 1
  evaluation_periods        = 1
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
        FunctionName = aws_lambda_function.pass_fail_py.function_name
      }
    }
    return_data = true
  }
}
