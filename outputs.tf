# curl "$(terraform output -raw api_gw_base_url)/hello"
output "api_gw_base_url" {
  description = "Base URL for API Gateway stage."
  value = aws_apigatewayv2_stage.lambda.invoke_url
}

output "function_http_handler_py_name" {
  value = aws_lambda_function.http_handler_py.function_name
}

output "function_simple_check_py_name" {
  value = aws_lambda_function.simple_check_py.function_name
}
