data "archive_file" "command_go" {
  type        = "zip"
  source_file = "${path.module}/command_go/handler"
  output_path = "${path.module}/command_go.zip"
}

resource "aws_lambda_function" "command_go" {
  filename         = data.archive_file.command_go.output_path
  function_name    = "command_go"
  role             = aws_iam_role.lincas_lambda_role.arn
  handler          = "handler"
  runtime          = "go1.x"
  timeout          = 60
  source_code_hash = filebase64sha256(data.archive_file.command_go.output_path)
  tags = merge(var.common_tags, {
    func = "command_go"
  })
  depends_on = [aws_cloudwatch_log_group.command_go]
}

resource "aws_cloudwatch_log_group" "command_go" {
  name              = "/aws/lambda/command_go"
  retention_in_days = 3
}

// TRIGGER: EventBridge (CloudWatch Events)
resource "aws_cloudwatch_event_target" "command_go" {
  rule = aws_cloudwatch_event_rule.default_schedule.name
  arn  = aws_lambda_function.command_go.arn
}

// TRIGGER: EventBridge (CloudWatch Events)
resource "aws_lambda_permission" "command_go" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.command_go.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.default_schedule.arn
}
