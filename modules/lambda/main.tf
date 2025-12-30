data "archive_file" "zip" {
  type        = "zip"
  source_file = "${path.module}/src/fred_fetcher.py"
  output_path = "${path.module}/src/fred_fetcher.zip"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.zip.output_path
  function_name    = "${var.project_name}-${var.environment}-fred-fetcher"
  role             = var.lambda_role_arn
  handler          = "fred_fetcher.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.zip.output_base64sha256

  environment {
    variables = {
      FRED_API_KEY = var.fred_api_key
    }
  }
}

resource "aws_lambda_permission" "allow_bedrock" {
  statement_id  = "AllowBedrockInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "bedrock.amazonaws.com"
}
