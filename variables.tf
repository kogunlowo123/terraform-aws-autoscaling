################################################################################
# General
################################################################################

variable "name" {
  description = "Name to be used for the Auto Scaling Group and related resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the Auto Scaling Group will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to launch resources in"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Launch Template
################################################################################

variable "image_id" {
  description = "AMI ID to use for the launch template"
  type        = string
}

variable "instance_type" {
  description = "Instance type to use for the launch template (used when mixed_instances_policy is not set)"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the instances"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile to associate with launched instances"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Base64-encoded user data to provide when launching instances"
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring for launched instances"
  type        = bool
  default     = true
}

################################################################################
# Auto Scaling Group
################################################################################

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = null
}

variable "health_check_type" {
  description = "Type of health check to perform. Valid values: EC2, ELB"
  type        = string
  default     = "EC2"
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "target_group_arns" {
  description = "List of target group ARNs for the Auto Scaling Group"
  type        = list(string)
  default     = []
}

variable "propagate_tags_at_launch" {
  description = "Whether to propagate tags to instances launched by the ASG"
  type        = bool
  default     = true
}

################################################################################
# Mixed Instances Policy
################################################################################

variable "mixed_instances_policy" {
  description = <<-EOT
    Configuration for mixed instances policy. When set, the ASG will use a mix of instance types.
    object({
      instances_distribution = optional(object({
        on_demand_allocation_strategy            = optional(string)
        on_demand_base_capacity                  = optional(number)
        on_demand_percentage_above_base_capacity = optional(number)
        spot_allocation_strategy                 = optional(string)
        spot_instance_pools                      = optional(number)
        spot_max_price                           = optional(string)
      }))
      override = optional(list(object({
        instance_type     = string
        weighted_capacity = optional(string)
      })))
    })
  EOT
  type = object({
    instances_distribution = optional(object({
      on_demand_allocation_strategy            = optional(string, "prioritized")
      on_demand_base_capacity                  = optional(number, 0)
      on_demand_percentage_above_base_capacity = optional(number, 100)
      spot_allocation_strategy                 = optional(string, "lowest-price")
      spot_instance_pools                      = optional(number, 2)
      spot_max_price                           = optional(string, "")
    }))
    override = optional(list(object({
      instance_type     = string
      weighted_capacity = optional(string)
    })))
  })
  default = null
}

################################################################################
# Warm Pool
################################################################################

variable "warm_pool" {
  description = <<-EOT
    Configuration for warm pool.
    object({
      pool_state                  = optional(string, "Stopped")
      min_size                    = optional(number, 0)
      max_group_prepared_capacity = optional(number)
    })
  EOT
  type = object({
    pool_state                  = optional(string, "Stopped")
    min_size                    = optional(number, 0)
    max_group_prepared_capacity = optional(number)
  })
  default = null
}

################################################################################
# Instance Refresh
################################################################################

variable "instance_refresh" {
  description = <<-EOT
    Configuration for instance refresh.
    object({
      strategy = optional(string, "Rolling")
      preferences = optional(object({
        min_healthy_percentage       = optional(number, 90)
        instance_warmup              = optional(number)
        checkpoint_delay             = optional(number)
        checkpoint_percentages       = optional(list(number))
        skip_matching                = optional(bool, false)
        auto_rollback                = optional(bool, false)
        scale_in_protected_instances = optional(string, "Ignore")
        standby_instances            = optional(string, "Ignore")
      }))
      triggers = optional(list(string))
    })
  EOT
  type = object({
    strategy = optional(string, "Rolling")
    preferences = optional(object({
      min_healthy_percentage       = optional(number, 90)
      instance_warmup              = optional(number)
      checkpoint_delay             = optional(number)
      checkpoint_percentages       = optional(list(number))
      skip_matching                = optional(bool, false)
      auto_rollback                = optional(bool, false)
      scale_in_protected_instances = optional(string, "Ignore")
      standby_instances            = optional(string, "Ignore")
    }))
    triggers = optional(list(string))
  })
  default = null
}

################################################################################
# Lifecycle Hooks
################################################################################

variable "lifecycle_hooks" {
  description = <<-EOT
    List of lifecycle hook configurations.
    list(object({
      name                    = string
      lifecycle_transition    = string
      default_result          = optional(string, "CONTINUE")
      heartbeat_timeout       = optional(number, 3600)
      notification_target_arn = optional(string)
      role_arn                = optional(string)
      notification_metadata   = optional(string)
    }))
  EOT
  type = list(object({
    name                    = string
    lifecycle_transition    = string
    default_result          = optional(string, "CONTINUE")
    heartbeat_timeout       = optional(number, 3600)
    notification_target_arn = optional(string)
    role_arn                = optional(string)
    notification_metadata   = optional(string)
  }))
  default = []
}

################################################################################
# Scaling Policies
################################################################################

variable "scaling_policies" {
  description = <<-EOT
    List of scaling policy configurations supporting target tracking, step, and predictive scaling.
    list(object({
      name                      = string
      policy_type               = string  # TargetTrackingScaling, StepScaling, PredictiveScaling
      estimated_instance_warmup = optional(number)
      adjustment_type           = optional(string)
      target_tracking = optional(object({
        predefined_metric_type = optional(string)
        target_value           = number
        resource_label         = optional(string)
        disable_scale_in       = optional(bool, false)
        customized_metric_specification = optional(object({
          metric_name = string
          namespace   = string
          statistic   = string
          unit        = optional(string)
          dimensions = optional(list(object({
            name  = string
            value = string
          })))
        }))
      }))
      step = optional(object({
        adjustment_type         = optional(string, "ChangeInCapacity")
        cooldown                = optional(number)
        min_adjustment_magnitude = optional(number)
        metric_aggregation_type = optional(string, "Average")
        step_adjustments = list(object({
          scaling_adjustment          = number
          metric_interval_lower_bound = optional(number)
          metric_interval_upper_bound = optional(number)
        }))
      }))
      predictive = optional(object({
        mode                          = optional(string, "ForecastAndScale")
        scheduling_buffer_time        = optional(number)
        max_capacity_breach_behavior  = optional(string, "HonorMaxCapacity")
        max_capacity_buffer           = optional(number)
        metric_specification = object({
          target_value = number
          predefined_scaling_metric_specification = optional(object({
            predefined_metric_type = string
            resource_label         = optional(string)
          }))
          predefined_load_metric_specification = optional(object({
            predefined_metric_type = string
            resource_label         = optional(string)
          }))
          customized_scaling_metric_specification = optional(object({
            metric_data_queries = list(object({
              id         = string
              expression = optional(string)
              label      = optional(string)
              metric_stat = optional(object({
                metric = object({
                  metric_name = string
                  namespace   = string
                  dimensions = optional(list(object({
                    name  = string
                    value = string
                  })))
                })
                stat = string
                unit = optional(string)
              }))
              return_data = optional(bool)
            }))
          }))
          customized_load_metric_specification = optional(object({
            metric_data_queries = list(object({
              id         = string
              expression = optional(string)
              label      = optional(string)
              metric_stat = optional(object({
                metric = object({
                  metric_name = string
                  namespace   = string
                  dimensions = optional(list(object({
                    name  = string
                    value = string
                  })))
                })
                stat = string
                unit = optional(string)
              }))
              return_data = optional(bool)
            }))
          }))
          customized_capacity_metric_specification = optional(object({
            metric_data_queries = list(object({
              id         = string
              expression = optional(string)
              label      = optional(string)
              metric_stat = optional(object({
                metric = object({
                  metric_name = string
                  namespace   = string
                  dimensions = optional(list(object({
                    name  = string
                    value = string
                  })))
                })
                stat = string
                unit = optional(string)
              }))
              return_data = optional(bool)
            }))
          }))
        })
      }))
    }))
  EOT
  type = list(object({
    name                      = string
    policy_type               = string
    estimated_instance_warmup = optional(number)
    adjustment_type           = optional(string)
    target_tracking = optional(object({
      predefined_metric_type = optional(string)
      target_value           = number
      resource_label         = optional(string)
      disable_scale_in       = optional(bool, false)
      customized_metric_specification = optional(object({
        metric_name = string
        namespace   = string
        statistic   = string
        unit        = optional(string)
        dimensions = optional(list(object({
          name  = string
          value = string
        })))
      }))
    }))
    step = optional(object({
      adjustment_type          = optional(string, "ChangeInCapacity")
      cooldown                 = optional(number)
      min_adjustment_magnitude = optional(number)
      metric_aggregation_type  = optional(string, "Average")
      step_adjustments = list(object({
        scaling_adjustment          = number
        metric_interval_lower_bound = optional(number)
        metric_interval_upper_bound = optional(number)
      }))
    }))
    predictive = optional(object({
      mode                         = optional(string, "ForecastAndScale")
      scheduling_buffer_time       = optional(number)
      max_capacity_breach_behavior = optional(string, "HonorMaxCapacity")
      max_capacity_buffer          = optional(number)
      metric_specification = object({
        target_value = number
        predefined_scaling_metric_specification = optional(object({
          predefined_metric_type = string
          resource_label         = optional(string)
        }))
        predefined_load_metric_specification = optional(object({
          predefined_metric_type = string
          resource_label         = optional(string)
        }))
        customized_scaling_metric_specification = optional(object({
          metric_data_queries = list(object({
            id         = string
            expression = optional(string)
            label      = optional(string)
            metric_stat = optional(object({
              metric = object({
                metric_name = string
                namespace   = string
                dimensions = optional(list(object({
                  name  = string
                  value = string
                })))
              })
              stat = string
              unit = optional(string)
            }))
            return_data = optional(bool)
          }))
        }))
        customized_load_metric_specification = optional(object({
          metric_data_queries = list(object({
            id         = string
            expression = optional(string)
            label      = optional(string)
            metric_stat = optional(object({
              metric = object({
                metric_name = string
                namespace   = string
                dimensions = optional(list(object({
                  name  = string
                  value = string
                })))
              })
              stat = string
              unit = optional(string)
            }))
            return_data = optional(bool)
          }))
        }))
        customized_capacity_metric_specification = optional(object({
          metric_data_queries = list(object({
            id         = string
            expression = optional(string)
            label      = optional(string)
            metric_stat = optional(object({
              metric = object({
                metric_name = string
                namespace   = string
                dimensions = optional(list(object({
                  name  = string
                  value = string
                })))
              })
              stat = string
              unit = optional(string)
            }))
            return_data = optional(bool)
          }))
        }))
      })
    }))
  }))
  default = []
}

################################################################################
# Scheduled Actions
################################################################################

variable "scheduled_actions" {
  description = <<-EOT
    List of scheduled action configurations.
    list(object({
      name             = string
      min_size         = optional(number)
      max_size         = optional(number)
      desired_capacity = optional(number)
      start_time       = optional(string)
      end_time         = optional(string)
      recurrence       = optional(string)
      time_zone        = optional(string)
    }))
  EOT
  type = list(object({
    name             = string
    min_size         = optional(number)
    max_size         = optional(number)
    desired_capacity = optional(number)
    start_time       = optional(string)
    end_time         = optional(string)
    recurrence       = optional(string)
    time_zone        = optional(string)
  }))
  default = []
}

################################################################################
# Instance Maintenance Policy
################################################################################

variable "instance_maintenance_policy" {
  description = <<-EOT
    Instance maintenance policy for the Auto Scaling Group.
    object({
      min_healthy_percentage = optional(number, 90)
      max_healthy_percentage = optional(number, 120)
    })
  EOT
  type = object({
    min_healthy_percentage = optional(number, 90)
    max_healthy_percentage = optional(number, 120)
  })
  default = null
}

################################################################################
# Notifications
################################################################################

variable "notification_topic_arn" {
  description = "ARN of the SNS topic for ASG notifications"
  type        = string
  default     = null
}

variable "notification_types" {
  description = "List of notification types to subscribe to"
  type        = list(string)
  default = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
}
