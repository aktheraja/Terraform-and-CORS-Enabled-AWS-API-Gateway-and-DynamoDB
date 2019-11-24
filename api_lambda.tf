resource "aws_api_gateway_rest_api" "cors_api" {
  name          = "MyAPI"
  description   = "API CORS-enabled methods."
}
resource "aws_api_gateway_resource" "cors_resource" {
  path_part     = "Employee"
  parent_id     = "${aws_api_gateway_rest_api.cors_api.root_resource_id}"
  rest_api_id   = "${aws_api_gateway_rest_api.cors_api.id}"
}
resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.cors_api.id}"
  resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id   = "${aws_api_gateway_rest_api.cors_api.id}"
  resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
  http_method   = "${aws_api_gateway_method.options_method.http_method}"
  status_code   = "200"
  response_models ={
    "application/json" = "Empty"
  }
  response_parameters ={
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = ["aws_api_gateway_method.options_method"]
}
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id   = "${aws_api_gateway_rest_api.cors_api.id}"
  resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
  http_method   = "${aws_api_gateway_method.options_method.http_method}"
  type          = "MOCK"
  depends_on = ["aws_api_gateway_method.options_method"]
}
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id   = "${aws_api_gateway_rest_api.cors_api.id}"
  resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
  http_method   = "${aws_api_gateway_method.options_method.http_method}"
  status_code   = "${aws_api_gateway_method_response.options_200.status_code}"
  response_parameters = {
  "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  depends_on = ["aws_api_gateway_method_response.options_200"]
}


resource "aws_api_gateway_method" "cors_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.cors_api.id}"
  resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
  http_method   = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_method_response" "cors_method_response_200" {
  rest_api_id   = "${aws_api_gateway_rest_api.cors_api.id}"
  resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
  http_method   = "${aws_api_gateway_method.cors_method.http_method}"
  status_code   = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = ["aws_api_gateway_method.cors_method"]
}
resource "aws_api_gateway_integration" "integration" {
  rest_api_id   = "${aws_api_gateway_rest_api.cors_api.id}"
  resource_id   = "${aws_api_gateway_resource.cors_resource.id}"
  http_method   = "${aws_api_gateway_method.cors_method.http_method}"
  integration_http_method = "POST"
  type          = "AWS_PROXY"
  uri           = "arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"
  depends_on    = ["aws_api_gateway_method.cors_method", "aws_lambda_function.lambda"]
}
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id   = "${aws_api_gateway_rest_api.cors_api.id}"
  stage_name    = "Dev"
  depends_on    = ["aws_api_gateway_integration.integration"]
}
# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-west-2:695245289132:${aws_api_gateway_rest_api.cors_api.id}/*/${aws_api_gateway_method.cors_method.http_method}/Employee"
}
resource "aws_lambda_function" "lambda" {
  filename         = "lambda.zip"
  function_name    = "API_GATEWAY_PREPROCESS"
  role             = "${aws_iam_role.role.arn}"
  handler          = "lambda.lambda_handler"
  runtime          = "python3.7"
  timeout          = 60
  source_code_hash = "${filebase64sha256("${path.module}/lambda.zip")}"
  environment {
    variables = {
      DYNAMODB_TABLE = "Cloud_Infrastructure"
    }
  }
}
resource "aws_iam_role" "role" {
  name = "myrole"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "lifecycle" {
  name   = "tf_lambda_vpc_policy"
  path   = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": "dynamodb:*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "lifecycle" {
  name       = "tf-iam-role-attachment-lifecycle"
  roles      = ["${aws_iam_role.role.name}"]
  policy_arn = "${aws_iam_policy.lifecycle.arn}"
}
