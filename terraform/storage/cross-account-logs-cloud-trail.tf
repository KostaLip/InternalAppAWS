resource "aws_cloudtrail" "name" {
  provider = aws.management

  name = "cross-account-logs"
  s3_bucket_name = aws_s3_bucket.storage-logging.bucket

  is_organization_trail = true
  is_multi_region_trail = false
  include_global_service_events = true
  enable_log_file_validation = true
  enable_logging = true

  depends_on = [ aws_s3_bucket_policy.allow-org-cloudtrail, aws_s3_bucket_ownership_controls.owner, aws_s3_bucket_public_access_block.central-logs]
}