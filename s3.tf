resource "aws_s3_bucket" "logs_bucket" {
  bucket = var.bucket_name
  force_destroy = true

  lifecycle_rule {
    id      = "expire-logs"
    enabled = true
    expiration {
      days = 7
    }
    prefix = ""
  }

  tags = {
    Name = "AppLogs"
  }
}

resource "aws_s3_bucket_acl" "private_acl" {
  bucket = aws_s3_bucket.logs_bucket.id
  acl    = "private"
}
