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

resource "aws_cloudwatch_log_metric_filter" "simple_check_return_code" {
  name           = "Filter - SimpleCheckPy - ReturnCode"
  pattern        = "{ $.return_code = \"*\" }"
  log_group_name = aws_cloudwatch_log_group.simple_check_py.name

  metric_transformation {
    name      = "LambdaSimpleCheckPyReturnCode"
    namespace = "LogMetrics"
    value     = "$.return_code"
    unit      = "None"
  }
}

resource "aws_cloudwatch_log_metric_filter" "simple_check_py_success" {
  name           = "Filter - SimpleCheckPy - Success"
  pattern        = "{ $.return_code = 0 }"
  log_group_name = aws_cloudwatch_log_group.simple_check_py.name

  metric_transformation {
    name      = "LambdaSimpleCheckPyReturnCodeSuccess"
    namespace = "LogMetrics"
    value     = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "simple_check_py_failure" {
  name           = "Filter - SimpleCheckPy - Failure"
  pattern        = "{ $.return_code != 0 }"
  log_group_name = aws_cloudwatch_log_group.simple_check_py.name

  metric_transformation {
    name      = "LambdaSimpleCheckPyReturnCodeFailure"
    namespace = "LogMetrics"
    value     = "1"
  }
}

// NOTE: populates CloudWatch - Log Insights
resource "aws_cloudwatch_query_definition" "simple_check_py_return_code_failures" {
  name            = "Lambda - SimpleCheckPy - ReturnCode - Failures"
  log_group_names = [aws_cloudwatch_log_group.simple_check_py.name]

  query_string = <<EOF
 fields @timestamp, @message, @return_code
 | filter @message like "RESPONSE:"
 | filter return_code != 0
 | sort @timestamp desc
 | limit 20
 | stats count() by @message
EOF
}

// NOTE: alternative: stats count() by @message
resource "aws_cloudwatch_query_definition" "simple_check_py_return_code_success" {
  name            = "Lambda - SimpleCheckPy - ReturnCode - Success"
  log_group_names = [aws_cloudwatch_log_group.simple_check_py.name]

  query_string = <<EOF
 fields @timestamp, @message, @return_code
 | filter @message like "RESPONSE:"
 | filter return_code = 0
 | sort @timestamp desc
 | limit 20
 | stats count() by @message
EOF
}
