resource "aws_s3_bucket" "storage-logging" {
  provider = aws.storage-logging
  bucket = "internalapp-storage-logging"
}

resource "aws_s3_bucket_ownership_controls" "owner" {
  provider = aws.storage-logging
  bucket = aws_s3_bucket.storage-logging.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "central-logs" {
  provider = aws.storage-logging
  bucket = aws_s3_bucket.storage-logging.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow-org-cloudtrail" {
  provider = aws.storage-logging
  bucket = aws_s3_bucket.storage-logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = { Service = "cloudtrail.amazonaws.com" }
            Action = "s3:GetBucketAcl"
            Resource = aws_s3_bucket.storage-logging.arn
            Condition = {
                StringEquals = {
                    "aws:SourceArn" = "arn:aws:cloudtrail:eu-central-1:093410165669:trail/cross-account-logs"
                }
            }
        },
        {
            Effect = "Allow"
            Principal = { Service = "cloudtrail.amazonaws.com" }
            Action = "s3:PutObject"
            Resource = "${aws_s3_bucket.storage-logging.arn}/AWSLogs/*"
            Condition = {
                StringEquals = {
                    "s3:x-amz-acl"  = "bucket-owner-full-control"
                    "aws:SourceArn" = "arn:aws:cloudtrail:eu-central-1:093410165669:trail/cross-account-logs"
                }
            }
        },
        {
            Sid = "AWSCloudTrailGetPolicy"
            Effect = "Allow"
            Principal = { Service = "cloudtrail.amazonaws.com" }
            Action = "s3:GetBucketPolicy"
            Resource = aws_s3_bucket.storage-logging.arn
        }
    ]
  })
}