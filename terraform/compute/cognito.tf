resource "aws_cognito_user_pool" "user-pool" {
  name = "internal-app-users"
  provider = aws.compute

  password_policy {
    minimum_length = 8
  }
  auto_verified_attributes = [ "email" ]
}

resource "aws_cognito_user_pool_client" "user-pool-client" {
  name = "internal-app-client"
  provider = aws.compute
  user_pool_id = aws_cognito_user_pool.user-pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  allowed_oauth_flows = [ "implicit" ]
  allowed_oauth_scopes = [ "openid", "email", "profile" ]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = ["https://example.com/callback"]
  supported_identity_providers = [ "COGNITO" ]
  generate_secret = false
}

resource "aws_cognito_user_pool_domain" "user-pool-doamin" {
  provider = aws.compute
  domain = "internalappkostalip"
  user_pool_id = aws_cognito_user_pool.user-pool.id
}