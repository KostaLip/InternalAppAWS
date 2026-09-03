resource "aws_iam_role" "datasync_s3_role" {
  provider = aws.storage-datasync
  name = "datasync-s3-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {Service = "datasync.amazonaws.com"}
        Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "datasync_s3_policy" {
  provider = aws.storage-datasync
  name = "datasync-s3-policy"
  role = aws_iam_role.datasync_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [aws_s3_bucket.storage-datasync.arn, "${aws_s3_bucket.storage-datasync.arn}/*"]
      }
    ]
  })
}

resource "awscc_datasync_location_azure_blob" "source" {
  provider = awscc.storage-datasync
  azure_blob_container_url = "https://datasyncstorageaccountte.blob.core.windows.net/datasync-source"
  azure_blob_authentication_type = "SAS"

  azure_blob_sas_configuration = {
    azure_blob_sas_token = var.azure_sas_token
  }

  azure_blob_type = "BLOCK"
}

resource "awscc_datasync_location_s3" "destination" {
  provider = awscc.storage-datasync
  s3_bucket_arn = aws_s3_bucket.storage-datasync.arn
  subdirectory = "/"

  s3_config = {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

resource "awscc_datasync_task" "azure_to_s3" {
  provider = awscc.storage-datasync
  source_location_arn = awscc_datasync_location_azure_blob.source.location_arn
  destination_location_arn = awscc_datasync_location_s3.destination.location_arn
  name = "azure-to-s3-sync"
  task_mode = "ENHANCED"

  options = {
    verify_mode = "ONLY_FILES_TRANSFERRED"
    object_tags = "NONE"
  }

  schedule = {
    schedule_expression = "cron(28 * * * ? *)"
  }
}