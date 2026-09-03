resource "aws_apigatewayv2_api" "api-gateway" {
  provider = aws.compute
  name = "internal-app"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [ "*" ]
    allow_methods = [ "GET", "POST", "OPTIONS" ]
    allow_headers = [ "Authorization", "Content-Type" ]
  }
}

resource "aws_apigatewayv2_authorizer" "api-gateway-authorizer" {
  provider = aws.compute
  api_id = aws_apigatewayv2_api.api-gateway.id
  name = "cognito-authorizer"
  authorizer_type = "JWT"
  identity_sources = [ "$request.header.Authorization" ]

  jwt_configuration {
    audience = [ aws_cognito_user_pool_client.user-pool-client.id ]
    issuer = "https://cognito-idp.eu-central-1.amazonaws.com/${aws_cognito_user_pool.user-pool.id}"
  }
}

resource "aws_apigatewayv2_stage" "default" {
  provider = aws.compute
  api_id = aws_apigatewayv2_api.api-gateway.id
  name = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "get-results" {
  provider = aws.compute
  api_id = aws_apigatewayv2_api.api-gateway.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.get-results.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get-results" {
  provider = aws.compute
  api_id = aws_apigatewayv2_api.api-gateway.id
  route_key = "GET /results"
  target = "integrations/${aws_apigatewayv2_integration.get-results.id}"
  authorization_type = "JWT"
  authorizer_id = aws_apigatewayv2_authorizer.api-gateway-authorizer.id
}

resource "aws_lambda_permission" "api-gateway-get-results" {
  provider = aws.compute
  statement_id = "AllowAPIGatewayInvokeGetResults"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get-results.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.api-gateway.execution_arn}/*/*"
}