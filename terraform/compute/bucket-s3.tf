resource "aws_s3_bucket" "storage-s3" {
  provider = aws.storage-s3
  bucket = "internalapp-storage-s3"
}

resource "aws_s3_bucket_policy" "storage-cross-account-write" {
  bucket = aws_s3_bucket.storage-s3.id
  provider = aws.storage-s3
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:ListBucket"]
        Principal = { AWS = "arn:aws:iam::093410165669:role/process-data-lambda-role" }
        Resource = [
          aws_s3_bucket.storage-s3.arn,
          "${aws_s3_bucket.storage-s3.arn}/*"
        ]
      },
      {

        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Principal = { AWS = "arn:aws:iam::803888670729:role/get-results-lambda-role" }
        Resource = [
          aws_s3_bucket.storage-s3.arn,
          "${aws_s3_bucket.storage-s3.arn}/*"
        ]
      }
    ]
  })
}