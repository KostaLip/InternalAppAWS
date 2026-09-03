resource "aws_iam_role" "get-results-role" {
  provider = aws.compute
  name = "get-results-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "get-results-basic" {
  provider = aws.compute
  role = aws_iam_role.get-results-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "get-results-s3-read" {
  provider = aws.compute
  name = "get-results-s3-read"
  role = aws_iam_role.get-results-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.storage-s3.arn,
          "${aws_s3_bucket.storage-s3.arn}/*"
        ]
      }
    ]
  })
}

data "archive_file" "get-results-zip" {
  type = "zip"
  source_dir = "${path.module}/get-results-src"
  output_path = "${path.module}/get-results-package.zip"
}

resource "aws_lambda_function" "get-results" {
  provider = aws.compute
  function_name = "get-results"
  role = aws_iam_role.get-results-role.arn
  handler = "index.handler"
  runtime = "python3.11"
  filename = data.archive_file.get-results-zip.output_path
  source_code_hash = data.archive_file.get-results-zip.output_base64sha256
  timeout = 15

  environment {
    variables = {
      RESULTS_BUCKET = "internalapp-storage-s3"
    }
  }
}