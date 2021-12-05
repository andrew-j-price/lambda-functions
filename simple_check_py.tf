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
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_default_secgroup.id]
  }
  tags = merge(var.common_tags, {
    func = "simple_check_py"
  })

}