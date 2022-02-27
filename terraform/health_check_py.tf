data "archive_file" "health_check_py" {
  type        = "zip"
  source_dir  = "${path.module}/../health_check_py"
  output_path = "${path.module}/health_check_py.zip"
}

resource "aws_lambda_function" "health_check_py" {
  filename         = data.archive_file.health_check_py.output_path
  function_name    = "health_check_py"
  role             = aws_iam_role.lincas_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 60
  source_code_hash = filebase64sha256(data.archive_file.health_check_py.output_path)
  environment {
    variables = {
      ATTEST_BASE_URL = var.attest_base_url,
      PROXY_SERVER = var.proxy_server_url,
    }
  }
  /* NOTES:
     vpc_config is optional, internet bound traffic does not have to be in VPC, but VPC bound traffic must be in private subnet
     For IPv4 outbound traffic, VPC needs NAT Gateway or NAT Instance
     For IPv6 outbound traffic, tried egress-only-gateway but would not work for Lambda functions however did work on EC2 instances in the same private subnet
     When using Squid Proxy Server, was able to get outbound IPv4 and IPv6 traffic
  */
  // /*
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_default_secgroup.id]
  }
  // */
  tags = merge(var.common_tags, {
    func = "health_check_py"
  })
  depends_on = [aws_cloudwatch_log_group.health_check_py]
}

resource "aws_cloudwatch_log_group" "health_check_py" {
  name              = "/aws/lambda/health_check_py"
  retention_in_days = 3
}

// TRIGGER: EventBridge (CloudWatch Events)
resource "aws_cloudwatch_event_target" "health_check_py" {
  rule = aws_cloudwatch_event_rule.default_schedule.name
  arn  = aws_lambda_function.health_check_py.arn
}

// TRIGGER: EventBridge (CloudWatch Events)
resource "aws_lambda_permission" "health_check_py" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_check_py.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.default_schedule.arn
}

// Lambda Function failire - SNS Integration
// NOTE: ideally this will not occur with our error handling and preference to Return Code
resource "aws_cloudwatch_metric_alarm" "health_check_py_failure" {
  alarm_name                = "health_check_py_failure"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 1
  evaluation_periods        = 2
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
        FunctionName = aws_lambda_function.health_check_py.function_name
      }
    }
    return_data = true
  }
}

// Return Code - Metric Log
resource "aws_cloudwatch_log_metric_filter" "health_check_py_return_code" {
  name           = "LambdaHealthCheckPyReturnCode"
  pattern        = "{ $.return_code = \"*\" }"
  log_group_name = aws_cloudwatch_log_group.health_check_py.name
  // NOTE: keep `name` the same for aws_cloudwatch_metric_alarm integration
  metric_transformation {
    name      = "LambdaHealthCheckPyReturnCode"
    namespace = "LogMetrics"
    value     = "$.return_code"
    unit      = "None"
  }
}

// Return Code - SNS Integration
resource "aws_cloudwatch_metric_alarm" "health_check_py_return_code_failure" {
  namespace                 = "LogMetrics"
  alarm_name                = "health_check_py_return_code_failure"
  metric_name               = aws_cloudwatch_log_metric_filter.health_check_py_return_code.name
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 1
  evaluation_periods        = 2
  datapoints_to_alarm       = 2
  period                    = 1800 # seconds
  statistic                 = "Maximum"
  unit                      = "None"
  alarm_actions             = [aws_sns_topic.notifications_topic.arn]
  insufficient_data_actions = []
  treat_missing_data        = "ignore"
}

/*
// NOTE: not as useful, but keeping for reference
resource "aws_cloudwatch_log_metric_filter" "health_check_py_success" {
  name           = "Filter - HealthCheckPy - Success"
  pattern        = "{ $.return_code = 0 }"
  log_group_name = aws_cloudwatch_log_group.health_check_py.name

  metric_transformation {
    name      = "LambdaHealthCheckPyReturnCodeSuccess"
    namespace = "LogMetrics"
    value     = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "health_check_py_failure" {
  name           = "Filter - HealthCheckPy - Failure"
  pattern        = "{ $.return_code != 0 }"
  log_group_name = aws_cloudwatch_log_group.health_check_py.name

  metric_transformation {
    name      = "LambdaHealthCheckPyReturnCodeFailure"
    namespace = "LogMetrics"
    value     = "1"
  }
}
*/

// NOTE: populates CloudWatch - Log Insights
resource "aws_cloudwatch_query_definition" "health_check_py_return_code_failures" {
  name            = "Lambda - HealthCheckPy - ReturnCode - Failures"
  log_group_names = [aws_cloudwatch_log_group.health_check_py.name]

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
resource "aws_cloudwatch_query_definition" "health_check_py_return_code_success" {
  name            = "Lambda - HealthCheckPy - ReturnCode - Success"
  log_group_names = [aws_cloudwatch_log_group.health_check_py.name]

  query_string = <<EOF
 fields @timestamp, @message, @return_code
 | filter @message like "RESPONSE:"
 | filter return_code = 0
 | sort @timestamp desc
 | limit 20
 | stats count() by @message
EOF
}
