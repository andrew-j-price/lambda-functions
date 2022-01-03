data "archive_file" "instruct_go" {
  type        = "zip"
  source_file = "${path.module}/../instruct_go/handler"
  output_path = "${path.module}/instruct_go.zip"
}

resource "aws_lambda_function" "instruct_go" {
  filename         = data.archive_file.instruct_go.output_path
  function_name    = "instruct_go"
  role             = aws_iam_role.lincas_lambda_role.arn
  handler          = "handler"
  runtime          = "go1.x"
  timeout          = 60
  source_code_hash = filebase64sha256(data.archive_file.instruct_go.output_path)
  tags = merge(var.common_tags, {
    func = "instruct_go"
  })
  depends_on = [aws_cloudwatch_log_group.instruct_go]
}

resource "aws_cloudwatch_log_group" "instruct_go" {
  name              = "/aws/lambda/instruct_go"
  retention_in_days = 3
}

// TRIGGER: EventBridge (CloudWatch Events)
resource "aws_cloudwatch_event_target" "instruct_go" {
  rule = aws_cloudwatch_event_rule.default_schedule.name
  arn  = aws_lambda_function.instruct_go.arn
}

// TRIGGER: EventBridge (CloudWatch Events)
resource "aws_lambda_permission" "instruct_go" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.instruct_go.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.default_schedule.arn
}
