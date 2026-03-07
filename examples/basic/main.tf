provider "aws" {
  region = "us-east-1"
}

module "autoscaling" {
  source = "../../"

  name       = "basic-asg"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  image_id      = "ami-0123456789abcdef0"
  instance_type = "t3.micro"

  min_size         = 1
  max_size          = 3
  desired_capacity = 2

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tags = {
    Environment = "dev"
    Project     = "basic-example"
  }
}
