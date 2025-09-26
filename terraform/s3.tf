# Private S3 bucket (name must be passed in)
resource "aws_s3_bucket" "logs" {
  bucket        = var.s3_bucket_name
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_acl" "logs_acl" {
  bucket = aws_s3_bucket.logs.id
  acl    = "private"
}

# Lifecycle rule to delete logs after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "delete-logs"
    status = "Enabled"

    filter {}
    expiration {
      days = 7
    }
  }
}
