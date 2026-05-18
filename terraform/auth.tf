# 1. AWS Cognito User Pool (The secure database for user credentials)
resource "aws_cognito_user_pool" "main" {
  name = "main-production-user-pool"

  # Enforce basic production-grade password complexity rules
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Automatically verify email addresses
  auto_verified_attributes = ["email"]

  tags = {
    Name        = "main-production-user-pool"
    Environment = "main-production-app-client"
  }
}

# 2. Cognito User Pool Client (Allows your web application to communicate with Cognito)
resource "aws_cognito_user_pool_client" "client" {
  name         = "main-production-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
}

