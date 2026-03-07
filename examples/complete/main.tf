provider "aws" {
  region = "us-east-1"
}

module "autoscaling" {
  source = "../../"

  name       = "complete-asg"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1", "subnet-0123456789abcdef2"]

  image_id                 = "ami-0123456789abcdef0"
  instance_type            = "t3.large"
  key_name                 = "my-key-pair"
  security_group_ids       = ["sg-0123456789abcdef0"]
  iam_instance_profile_arn = "arn:aws:iam::123456789012:instance-profile/my-instance-profile"
  enable_monitoring        = true
  user_data                = base64encode("#!/bin/bash\necho 'Hello World'")

  min_size         = 3
  max_size          = 20
  desired_capacity = 6

  health_check_type         = "ELB"
  health_check_grace_period = 600
  target_group_arns = [
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/tg-1/1234567890abcdef",
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/tg-2/abcdef1234567890",
  ]

  # Mixed instances policy with diverse instance types
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_allocation_strategy            = "prioritized"
      on_demand_base_capacity                  = 2
      on_demand_percentage_above_base_capacity = 30
      spot_allocation_strategy                 = "lowest-price"
      spot_instance_pools                      = 4
      spot_max_price                           = "0.05"
    }
    override = [
      { instance_type = "t3.large", weighted_capacity = "1" },
      { instance_type = "t3a.large", weighted_capacity = "1" },
      { instance_type = "m5.large", weighted_capacity = "1" },
      { instance_type = "m5a.large", weighted_capacity = "1" },
      { instance_type = "c5.large", weighted_capacity = "1" },
    ]
  }

  # Warm pool for pre-initialized instances
  warm_pool = {
    pool_state                  = "Hibernated"
    min_size                    = 2
    max_group_prepared_capacity = 8
  }

  # Instance refresh with checkpointing
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage       = 90
      instance_warmup              = 300
      checkpoint_delay             = 600
      checkpoint_percentages       = [20, 50, 100]
      skip_matching                = true
      auto_rollback                = true
      scale_in_protected_instances = "Ignore"
      standby_instances            = "Ignore"
    }
    triggers = ["tag", "desired_capacity"]
  }

  # Lifecycle hooks for launch and termination
  lifecycle_hooks = [
    {
      name                 = "instance-launching"
      lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 900
      notification_metadata = jsonencode({
        event = "launching"
        env   = "production"
      })
    },
    {
      name                 = "instance-terminating"
      lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 1200
      notification_metadata = jsonencode({
        event = "terminating"
        env   = "production"
      })
    },
  ]

  # Comprehensive scaling policies
  scaling_policies = [
    # Target tracking on CPU
    {
      name                      = "cpu-target-tracking"
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 300
      target_tracking = {
        predefined_metric_type = "ASGAverageCPUUtilization"
        target_value           = 40.0
        disable_scale_in       = false
      }
    },
    # Target tracking on ALB request count
    {
      name                      = "alb-request-tracking"
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 300
      target_tracking = {
        predefined_metric_type = "ALBRequestCountPerTarget"
        target_value           = 1000.0
        resource_label         = "app/my-alb/1234567890abcdef/targetgroup/tg-1/1234567890abcdef"
        disable_scale_in       = false
      }
    },
    # Step scaling for rapid scale-out
    {
      name        = "high-cpu-step-scaling"
      policy_type = "StepScaling"
      step = {
        adjustment_type         = "ChangeInCapacity"
        metric_aggregation_type = "Average"
        step_adjustments = [
          {
            scaling_adjustment          = 2
            metric_interval_lower_bound = 0
            metric_interval_upper_bound = 20
          },
          {
            scaling_adjustment          = 4
            metric_interval_lower_bound = 20
          },
        ]
      }
    },
    # Predictive scaling
    {
      name        = "predictive-cpu-scaling"
      policy_type = "PredictiveScaling"
      predictive = {
        mode                         = "ForecastAndScale"
        scheduling_buffer_time       = 300
        max_capacity_breach_behavior = "IncreaseMaxCapacity"
        max_capacity_buffer          = 20
        metric_specification = {
          target_value = 40.0
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

  # Scheduled actions for known traffic patterns
  scheduled_actions = [
    {
      name             = "scale-up-weekday-morning"
      min_size         = 6
      max_size         = 20
      desired_capacity = 10
      recurrence       = "0 8 * * 1-5"
      time_zone        = "America/New_York"
    },
    {
      name             = "scale-down-weekday-evening"
      min_size         = 3
      max_size         = 10
      desired_capacity = 4
      recurrence       = "0 20 * * 1-5"
      time_zone        = "America/New_York"
    },
    {
      name             = "scale-down-weekend"
      min_size         = 2
      max_size         = 6
      desired_capacity = 2
      recurrence       = "0 0 * * 6-7"
      time_zone        = "America/New_York"
    },
  ]

  # Instance maintenance policy
  instance_maintenance_policy = {
    min_healthy_percentage = 100
    max_healthy_percentage = 110
  }

  # SNS notifications
  notification_topic_arn = "arn:aws:sns:us-east-1:123456789012:asg-notifications"
  notification_types = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  propagate_tags_at_launch = true

  tags = {
    Environment = "production"
    Project     = "complete-example"
    Team        = "platform"
    CostCenter  = "12345"
  }
}
