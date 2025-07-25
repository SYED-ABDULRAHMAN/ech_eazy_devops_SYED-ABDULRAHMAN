resource "aws_instance" "dev_instance" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (Free tier)
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name      = "key1"
  user_data     = file("user_data.sh")

  tags = {
    Name = "DevApp"
  }
}
