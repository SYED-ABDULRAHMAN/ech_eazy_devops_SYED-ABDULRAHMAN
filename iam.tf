# Trust policy for EC2 to assume IAM roles
data "aws_iam_policy_document" "s3_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# S3 ReadOnly permissions for RoleA
data "aws_iam_policy_document" "s3_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = ["*"]
  }
}

# S3 UploadOnly permissions for RoleB
data "aws_iam_policy_document" "s3_upload_only" {
  statement {
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:PutObject"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Deny"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = ["*"]
  }
}

# IAM RoleA – S3 ReadOnly
resource "aws_iam_role" "s3_read_only" {
  name               = "s3-read-only-role"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
}

resource "aws_iam_role_policy" "s3_read_only_policy" {
  name   = "s3-read-only-policy"
  role   = aws_iam_role.s3_read_only.name
  policy = data.aws_iam_policy_document.s3_read_only.json
}

# IAM RoleB – S3 UploadOnly
resource "aws_iam_role" "s3_upload_only" {
  name               = "s3-upload-only-role"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
}

resource "aws_iam_role_policy" "s3_upload_only_policy" {
  name   = "s3-upload-only-policy"
  role   = aws_iam_role.s3_upload_only.name
  policy = data.aws_iam_policy_document.s3_upload_only.json
}

# Instance profile for EC2 to use RoleB
resource "aws_iam_instance_profile" "upload_profile" {
  name = "s3-upload-only-instance-profile"
  role = aws_iam_role.s3_upload_only.name
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-access-profile"
  role = aws_iam_role.s3_upload_only.name
}

