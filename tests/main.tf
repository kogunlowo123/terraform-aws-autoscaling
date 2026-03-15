terraform {
  required_version = ">= 1.7.0"
}

module "test" {
  source = "../"

  name       = "test-asg"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  image_id      = "ami-0123456789abcdef0"
  instance_type = "t3.medium"

  min_size         = 1
  max_size          = 3
  desired_capacity = 2

  health_check_type         = "EC2"
  health_check_grace_period = 300
  enable_monitoring         = true

  scaling_policies = [
    {
      name                      = "cpu-target-tracking"
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 300
      target_tracking = {
        predefined_metric_type = "ASGAverageCPUUtilization"
        target_value           = 70.0
        disable_scale_in       = false
      }
    }
  ]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
  }

  tags = {
    Test = "true"
  }
}
