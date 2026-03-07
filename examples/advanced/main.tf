provider "aws" {
  region = "us-east-1"
}

module "autoscaling" {
  source = "../../"

  name       = "advanced-asg"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1", "subnet-0123456789abcdef2"]

  image_id      = "ami-0123456789abcdef0"
  instance_type = "t3.medium"

  min_size         = 2
  max_size          = 10
  desired_capacity = 4

  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-tg/1234567890abcdef"]

  # Mixed instances policy with spot instances
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "lowest-price"
      spot_instance_pools                      = 3
    }
    override = [
      { instance_type = "t3.medium", weighted_capacity = "1" },
      { instance_type = "t3.large", weighted_capacity = "2" },
      { instance_type = "t3a.medium", weighted_capacity = "1" },
      { instance_type = "m5.large", weighted_capacity = "2" },
    ]
  }

  # Warm pool for faster scaling
  warm_pool = {
    pool_state                  = "Hibernated"
    min_size                    = 1
    max_group_prepared_capacity = 5
  }

  # Instance refresh for rolling deployments
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 90
      instance_warmup        = 300
      skip_matching          = true
      auto_rollback          = true
    }
    triggers = ["tag"]
  }

  # Lifecycle hooks
  lifecycle_hooks = [
    {
      name                 = "launch-hook"
      lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 300
    },
    {
      name                 = "terminate-hook"
      lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 600
    },
  ]

  # Target tracking scaling policy
  scaling_policies = [
    {
      name                      = "cpu-target-tracking"
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 300
      target_tracking = {
        predefined_metric_type = "ASGAverageCPUUtilization"
        target_value           = 50.0
        disable_scale_in       = false
      }
    },
    {
      name        = "predictive-cpu"
      policy_type = "PredictiveScaling"
      predictive = {
        mode                         = "ForecastAndScale"
        max_capacity_breach_behavior = "IncreaseMaxCapacity"
        max_capacity_buffer          = 10
        metric_specification = {
          target_value = 50.0
          predefined_scaling_metric_specification = {
            predefined_metric_type = "ASGAverageCPUUtilization"
          }
          predefined_load_metric_specification = {
            predefined_metric_type = "ASGTotalCPUUtilization"
          }
        }
      }
    },
  ]

  # Instance maintenance policy
  instance_maintenance_policy = {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  tags = {
    Environment = "staging"
    Project     = "advanced-example"
  }
}
