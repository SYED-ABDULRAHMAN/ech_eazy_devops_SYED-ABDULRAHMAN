resource "aws_launch_template" "app" {
  name_prefix   = "app-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_port        = var.app_port
    s3_bucket_name  = var.app_jar_bucket_name
  }))
}
