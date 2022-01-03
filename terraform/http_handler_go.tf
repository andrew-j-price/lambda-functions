data "archive_file" "http_handler_go" {
  type        = "zip"
  source_file = "${path.module}/../http_handler_go/handler"
  output_path = "${path.module}/http_handler_go.zip"
}

resource "aws_lambda_function" "http_handler_go" {
  filename         = data.archive_file.http_handler_go.output_path
  function_name    = "http_handler_go"
  role             = aws_iam_role.lincas_lambda_role.arn
  handler          = "handler"
  runtime          = "go1.x"
  timeout          = 60
  source_code_hash = filebase64sha256(data.archive_file.http_handler_go.output_path)
  tags = merge(var.common_tags, {
    func = "http_handler_go"
  })
  depends_on = [aws_cloudwatch_log_group.http_handler_go]
}

resource "aws_cloudwatch_log_group" "http_handler_go" {
  name              = "/aws/lambda/http_handler_go"
  retention_in_days = 3
}

resource "aws_apigatewayv2_integration" "http_handler_go" {
  api_id             = aws_apigatewayv2_api.lambda.id
  integration_uri    = aws_lambda_function.http_handler_go.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "http_handler_go" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "GET /hi"
  target    = "integrations/${aws_apigatewayv2_integration.http_handler_go.id}"
}

resource "aws_lambda_permission" "http_handler_go" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.http_handler_go.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
