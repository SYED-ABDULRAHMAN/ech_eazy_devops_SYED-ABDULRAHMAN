# Role A: Read-only S3
resource "aws_iam_role" "s3_read_role" {
  name = "s3-read-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "s3_read_policy" {
  name = "S3ReadOnly"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["s3:ListBucket", "s3:GetObject"],
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_read_policy" {
  role       = aws_iam_role.s3_read_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

# Role B: Write-only S3
resource "aws_iam_role" "s3_write_role" {
  name = "s3-write-only-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "s3_write_policy" {
  name = "S3WriteOnly"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["s3:PutObject", "s3:PutObjectAcl"],
        Effect   = "Allow",
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_write_policy" {
  role       = aws_iam_role.s3_write_role.name
  policy_arn = aws_iam_policy.s3_write_policy.arn
}

# Instance Profile for Role B
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-write-profile"
  role = aws_iam_role.s3_write_role.name
}
