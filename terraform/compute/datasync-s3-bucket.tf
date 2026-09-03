resource "aws_s3_bucket" "storage-datasync" {
  provider = aws.storage-datasync
  bucket = "internalapp-storage-datasync"
}

resource "aws_s3_bucket_policy" "datasync-cross-account-read" {
  bucket = aws_s3_bucket.storage-datasync.id
  provider = aws.storage-datasync
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::093410165669:role/process-data-lambda-role" }
        Action = ["s3:GetObject","s3:ListBucket"]
        Resource = [
          aws_s3_bucket.storage-datasync.arn,
          "${aws_s3_bucket.storage-datasync.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "datasync-trigger" {
  provider = aws.storage-datasync
  bucket = aws_s3_bucket.storage-datasync.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process-data.arn
    events = ["s3:ObjectCreated:*"]
  }

  depends_on = [ aws_lambda_permission.allow-data-sync-bucket ]
}