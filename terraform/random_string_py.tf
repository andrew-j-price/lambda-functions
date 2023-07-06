resource "aws_lambda_function" "random_string_py" {
  filename         = data.archive_file.random_string_py_archive.output_path
  function_name    = "random_string_py"
  role             = aws_iam_role.random_string_py_lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = var.python_runtime
  timeout          = 60
  source_code_hash = data.archive_file.random_string_py_archive.output_base64sha256
  layers           = [aws_lambda_layer_version.lambda_requirements.arn]
  depends_on = [
    aws_cloudwatch_log_group.random_string_py,
    data.archive_file.random_string_py_archive
  ]
  tags = merge(var.common_tags, {
    func = "random_string_py"
  })
}

data "archive_file" "random_string_py_archive" {
  type        = "zip"
  source_dir  = "${path.module}/../random_string_py"
  output_path = "${path.module}/random_string_py_code.zip"
}

data "archive_file" "random_string_py_requirements_layer" {
  type        = "zip"
  source_dir  = "${path.module}/random_string_py_lambda_layer"
  output_path = "${path.module}/random_string_py_lambda_layer.zip"
  depends_on = [
    null_resource.random_string_py_requirements_clean_folder,
    null_resource.random_requirements_py_requirements_pip_install,
  ]
}

resource "null_resource" "random_string_py_requirements_clean_folder" {
  triggers = {
    requirements = "${base64sha256(file("${path.module}/../random_string_py/requirements.txt"))}"
  }
  // Cleans/removes the current python module folder if exists
  provisioner "local-exec" {
    command = "cd ${path.module}/ && rm -rf ./random_string_py_lambda_layer"
  }
}

resource "null_resource" "random_requirements_py_requirements_pip_install" {
  triggers = {
    requirements = "${base64sha256(file("${path.module}/../random_string_py/requirements.txt"))}"
    fileexists   = fileexists("${path.module}/random_string_py_lambda_layer.zip")
  }
  // Here we install package requirements.  Python version here should match Lambda function target
  provisioner "local-exec" {
    command = "cd ${path.module}/ && python -m pip install --target ./random_string_py_lambda_layer/python/lib/${var.python_runtime}/site-packages -r ../random_string_py/requirements.txt"
  }
  depends_on = [null_resource.random_string_py_requirements_clean_folder]
}

resource "aws_lambda_layer_version" "lambda_requirements" {
  layer_name          = "random_string_py_requirements"
  filename            = data.archive_file.random_string_py_requirements_layer.output_path
  source_code_hash    = data.archive_file.random_string_py_requirements_layer.output_base64sha256
  compatible_runtimes = [var.python_runtime]
}

resource "aws_cloudwatch_log_group" "random_string_py" {
  name              = "/aws/lambda/random_string_py"
  retention_in_days = 3
}
resource "aws_apigatewayv2_integration" "random_string_py" {
  api_id             = aws_apigatewayv2_api.lambda.id
  integration_uri    = aws_lambda_function.random_string_py.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "random_string_py" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "GET /random"
  target    = "integrations/${aws_apigatewayv2_integration.random_string_py.id}"
}

resource "aws_lambda_permission" "random_string_py" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.random_string_py.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_iam_role" "random_string_py_lambda_exec" {
  name = "random_string_py_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
  managed_policy_arns = [
    aws_iam_policy.random_string_py_policy.arn,
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
  tags = merge(var.common_tags, {
    func = "random_string_py"
  })
}

resource "aws_iam_policy" "random_string_py_policy" {
  name = "random_string_py_policy"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "lambda:GetFunctionConfiguration"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function_url" "random_string_py_url" {
  count              = var.enable_function_url == true ? 1 : 0
  function_name      = aws_lambda_function.random_string_py.function_name
  authorization_type = "NONE"
}
