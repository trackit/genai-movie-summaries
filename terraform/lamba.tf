resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    interpreter = var.Terminal == "windows/git/bash" ? ["C:/Program Files/Git/bin/bash.exe", "-c"] : null
    command     = "pip3 install $(grep -ivE 'pandas' ../lambda/requirements.txt) -t ../python"
  }
  triggers = {
    run_on_requirements_change = filemd5("../lambda/requirements.txt")
  }
}

data "archive_file" "lambda_dependencies" {
  depends_on = [null_resource.install_dependencies]
  excludes   = [
    "__pycache__",
    "venv",
  ]

  source_dir  = "../python"
  output_path = "../python.zip"
  type        = "zip"
}

data "archive_file" "lambda_src" {
  excludes = [
    "__pycache__",
    "Pipfile",
    "Pipfile.lock",
    "requirements.txt"
  ]

  source_dir  = "../lambda/"
  output_path = "../code.zip"
  type        = "zip"
}

# not been used
resource "aws_lambda_layer_version" "lambda_dependencies_layer" {
  depends_on       = [data.archive_file.lambda_dependencies]
  filename         = "../python.zip"
  layer_name       = "movie_summaries_dependencies_layer"
  source_code_hash = data.archive_file.lambda_dependencies.output_base64sha256

  compatible_runtimes = ["python3.9"]
}

#

resource "aws_lambda_function" "summarize-movie" {
  function_name = "generate-summary"
  role          = aws_iam_role.lambda_role.arn
  handler       = "create-summary.lambda_handler"
  filename      = data.archive_file.lambda_src.output_path
  runtime       = "python3.9"
  timeout       = 120

  layers = [
    "arn:aws:lambda:us-west-2:770693421928:layer:Klayers-p311-boto3:5"
  ]

  source_code_hash = filebase64sha256(data.archive_file.lambda_src.output_path)

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.Video_transcription_DB.name
    }
  }
}

resource "aws_lambda_function" "list-movies" {
  function_name = "list-movies"
  role          = aws_iam_role.lambda_role.arn
  handler       = "list-movies.lambda_handler"
  filename      = data.archive_file.lambda_src.output_path
  runtime       = "python3.9"
  timeout       = 30

  layers = [
    "arn:aws:lambda:us-west-2:770693421928:layer:Klayers-p311-boto3:5"
  ]

  source_code_hash = filebase64sha256(data.archive_file.lambda_src.output_path)

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.Video_transcription_DB.name
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "movie-summary-api"
  description = "This API allow movie summarising"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "movie"
}

resource "aws_api_gateway_resource" "api_resource_id" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_resource.api_resource.id
  path_part   = "{jobName}"
}

resource "aws_api_gateway_method" "api_method_get" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "api_method_post" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource_id.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_integration_post" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.api_resource_id.id
  http_method = aws_api_gateway_method.api_method_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.summarize-movie.invoke_arn
}

resource "aws_api_gateway_integration" "api_integration_get" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.api_method_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list-movies.invoke_arn
}


resource "aws_lambda_permission" "summarize_movie_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.summarize-movie.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "list_movies_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list-movies.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.api_integration_post,
    aws_api_gateway_integration.api_integration_get,
    aws_lambda_permission.list_movies_lambda_permission,
    aws_lambda_permission.summarize_movie_lambda_permission,
  ]

  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = "prod"
}
