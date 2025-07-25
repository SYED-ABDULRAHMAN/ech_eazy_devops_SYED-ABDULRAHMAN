provider "aws" {
  region = "ap-south-1" # Change to your region
}

# Create private S3 bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.bucket_name
  force_destroy = true

  tags = {
    Name = "log-bucket"
  }
}

# Make the bucket private (no public access)
resource "aws_s3_bucket_public_access_block" "private_access" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add lifecycle rule to delete logs after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "delete-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 7
    }
  }
}

# Create EC2 instance with RoleB attached
resource "aws_instance" "log_uploader" {
  ami           = "ami-0f58b397bc5c1f2e8" # update if needed
  instance_type = "t2.micro"
  key_name      = "devops-key"           # ✅ Update with your actual key pair name

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = file("scripts/startup.sh")
  tags = {
    Name = "ec2-log-uploader"
  }
}


