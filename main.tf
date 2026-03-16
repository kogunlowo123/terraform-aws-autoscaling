################################################################################
# Launch Template
################################################################################

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-"
  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data

  monitoring {
    enabled = var.enable_monitoring
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_arn != null ? [1] : []
    content {
      arn = var.iam_instance_profile_arn
    }
  }

  dynamic "network_interfaces" {
    for_each = length(var.security_group_ids) > 0 ? [1] : []
    content {
      security_groups = var.security_group_ids
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = var.name })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = var.name })
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Auto Scaling Group
################################################################################

resource "aws_autoscaling_group" "this" {
  name                      = var.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  target_group_arns         = var.target_group_arns

  dynamic "launch_template" {
    for_each = var.mixed_instances_policy == null ? [1] : []
    content {
      id      = aws_launch_template.this.id
      version = "$Latest"
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.mixed_instances_policy != null ? [var.mixed_instances_policy] : []
    content {
      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.this.id
          version            = "$Latest"
        }

        dynamic "override" {
          for_each = mixed_instances_policy.value.override != null ? mixed_instances_policy.value.override : []
          content {
            instance_type     = override.value.instance_type
            weighted_capacity = override.value.weighted_capacity
          }
        }
      }

      dynamic "instances_distribution" {
        for_each = mixed_instances_policy.value.instances_distribution != null ? [mixed_instances_policy.value.instances_distribution] : []
        content {
          on_demand_allocation_strategy            = instances_distribution.value.on_demand_allocation_strategy
          on_demand_base_capacity                  = instances_distribution.value.on_demand_base_capacity
          on_demand_percentage_above_base_capacity = instances_distribution.value.on_demand_percentage_above_base_capacity
          spot_allocation_strategy                 = instances_distribution.value.spot_allocation_strategy
          spot_instance_pools                      = instances_distribution.value.spot_instance_pools
          spot_max_price                           = instances_distribution.value.spot_max_price
        }
      }
    }
  }

  dynamic "warm_pool" {
    for_each = var.warm_pool != null ? [var.warm_pool] : []
    content {
      pool_state                  = warm_pool.value.pool_state
      min_size                    = warm_pool.value.min_size
      max_group_prepared_capacity = warm_pool.value.max_group_prepared_capacity
    }
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null ? [var.instance_refresh] : []
    content {
      strategy = instance_refresh.value.strategy
      triggers = instance_refresh.value.triggers

      dynamic "preferences" {
        for_each = instance_refresh.value.preferences != null ? [instance_refresh.value.preferences] : []
        content {
          min_healthy_percentage       = preferences.value.min_healthy_percentage
          instance_warmup              = preferences.value.instance_warmup
          checkpoint_delay             = preferences.value.checkpoint_delay
          checkpoint_percentages       = preferences.value.checkpoint_percentages
          skip_matching                = preferences.value.skip_matching
          auto_rollback                = preferences.value.auto_rollback
          scale_in_protected_instances = preferences.value.scale_in_protected_instances
          standby_instances            = preferences.value.standby_instances
        }
      }
    }
  }

  dynamic "instance_maintenance_policy" {
    for_each = var.instance_maintenance_policy != null ? [var.instance_maintenance_policy] : []
    content {
      min_healthy_percentage = instance_maintenance_policy.value.min_healthy_percentage
      max_healthy_percentage = instance_maintenance_policy.value.max_healthy_percentage
    }
  }

  dynamic "tag" {
    for_each = [
      for key, value in merge(var.tags, { Name = var.name }) : {
        key                 = key
        value               = value
        propagate_at_launch = var.propagate_tags_at_launch
      }
    ]
    content {
      key                 = tag.value.key
      value               = tag.value.value
      propagate_at_launch = tag.value.propagate_at_launch
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

################################################################################
# Scaling Policies
################################################################################

resource "aws_autoscaling_policy" "this" {
  for_each = { for policy in var.scaling_policies : policy.name => policy }

  name                      = each.value.name
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = each.value.policy_type
  estimated_instance_warmup = each.value.estimated_instance_warmup
  adjustment_type           = each.value.policy_type == "StepScaling" ? each.value.step.adjustment_type : each.value.adjustment_type

  dynamic "target_tracking_configuration" {
    for_each = each.value.policy_type == "TargetTrackingScaling" && each.value.target_tracking != null ? [each.value.target_tracking] : []
    content {
      target_value     = target_tracking_configuration.value.target_value
      disable_scale_in = target_tracking_configuration.value.disable_scale_in

      dynamic "predefined_metric_specification" {
        for_each = target_tracking_configuration.value.predefined_metric_type != null ? [1] : []
        content {
          predefined_metric_type = target_tracking_configuration.value.predefined_metric_type
          resource_label         = target_tracking_configuration.value.resource_label
        }
      }

      dynamic "customized_metric_specification" {
        for_each = target_tracking_configuration.value.customized_metric_specification != null ? [target_tracking_configuration.value.customized_metric_specification] : []
        content {
          metric_name = customized_metric_specification.value.metric_name
          namespace   = customized_metric_specification.value.namespace
          statistic   = customized_metric_specification.value.statistic
          unit        = customized_metric_specification.value.unit

          dynamic "metric_dimension" {
            for_each = customized_metric_specification.value.dimensions != null ? customized_metric_specification.value.dimensions : []
            content {
              name  = metric_dimension.value.name
              value = metric_dimension.value.value
            }
          }
        }
      }
    }
  }

  dynamic "step_adjustment" {
    for_each = each.value.policy_type == "StepScaling" && each.value.step != null ? each.value.step.step_adjustments : []
    content {
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
      metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
      metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
    }
  }

  dynamic "predictive_scaling_configuration" {
    for_each = each.value.policy_type == "PredictiveScaling" && each.value.predictive != null ? [each.value.predictive] : []
    content {
      mode                         = predictive_scaling_configuration.value.mode
      scheduling_buffer_time       = predictive_scaling_configuration.value.scheduling_buffer_time
      max_capacity_breach_behavior = predictive_scaling_configuration.value.max_capacity_breach_behavior
      max_capacity_buffer          = predictive_scaling_configuration.value.max_capacity_buffer

      metric_specification {
        target_value = predictive_scaling_configuration.value.metric_specification.target_value

        dynamic "predefined_scaling_metric_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.predefined_scaling_metric_specification != null ? [predictive_scaling_configuration.value.metric_specification.predefined_scaling_metric_specification] : []
          content {
            predefined_metric_type = predefined_scaling_metric_specification.value.predefined_metric_type
            resource_label         = predefined_scaling_metric_specification.value.resource_label
          }
        }

        dynamic "predefined_load_metric_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.predefined_load_metric_specification != null ? [predictive_scaling_configuration.value.metric_specification.predefined_load_metric_specification] : []
          content {
            predefined_metric_type = predefined_load_metric_specification.value.predefined_metric_type
            resource_label         = predefined_load_metric_specification.value.resource_label
          }
        }

        dynamic "customized_scaling_metric_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.customized_scaling_metric_specification != null ? [predictive_scaling_configuration.value.metric_specification.customized_scaling_metric_specification] : []
          content {
            dynamic "metric_data_queries" {
              for_each = customized_scaling_metric_specification.value.metric_data_queries
              content {
                id          = metric_data_queries.value.id
                expression  = metric_data_queries.value.expression
                label       = metric_data_queries.value.label
                return_data = metric_data_queries.value.return_data

                dynamic "metric_stat" {
                  for_each = metric_data_queries.value.metric_stat != null ? [metric_data_queries.value.metric_stat] : []
                  content {
                    stat = metric_stat.value.stat
                    unit = metric_stat.value.unit

                    metric {
                      metric_name = metric_stat.value.metric.metric_name
                      namespace   = metric_stat.value.metric.namespace

                      dynamic "dimensions" {
                        for_each = metric_stat.value.metric.dimensions != null ? metric_stat.value.metric.dimensions : []
                        content {
                          name  = dimensions.value.name
                          value = dimensions.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "customized_load_metric_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.customized_load_metric_specification != null ? [predictive_scaling_configuration.value.metric_specification.customized_load_metric_specification] : []
          content {
            dynamic "metric_data_queries" {
              for_each = customized_load_metric_specification.value.metric_data_queries
              content {
                id          = metric_data_queries.value.id
                expression  = metric_data_queries.value.expression
                label       = metric_data_queries.value.label
                return_data = metric_data_queries.value.return_data

                dynamic "metric_stat" {
                  for_each = metric_data_queries.value.metric_stat != null ? [metric_data_queries.value.metric_stat] : []
                  content {
                    stat = metric_stat.value.stat
                    unit = metric_stat.value.unit

                    metric {
                      metric_name = metric_stat.value.metric.metric_name
                      namespace   = metric_stat.value.metric.namespace

                      dynamic "dimensions" {
                        for_each = metric_stat.value.metric.dimensions != null ? metric_stat.value.metric.dimensions : []
                        content {
                          name  = dimensions.value.name
                          value = dimensions.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "customized_capacity_metric_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.customized_capacity_metric_specification != null ? [predictive_scaling_configuration.value.metric_specification.customized_capacity_metric_specification] : []
          content {
            dynamic "metric_data_queries" {
              for_each = customized_capacity_metric_specification.value.metric_data_queries
              content {
                id          = metric_data_queries.value.id
                expression  = metric_data_queries.value.expression
                label       = metric_data_queries.value.label
                return_data = metric_data_queries.value.return_data

                dynamic "metric_stat" {
                  for_each = metric_data_queries.value.metric_stat != null ? [metric_data_queries.value.metric_stat] : []
                  content {
                    stat = metric_stat.value.stat
                    unit = metric_stat.value.unit

                    metric {
                      metric_name = metric_stat.value.metric.metric_name
                      namespace   = metric_stat.value.metric.namespace

                      dynamic "dimensions" {
                        for_each = metric_stat.value.metric.dimensions != null ? metric_stat.value.metric.dimensions : []
                        content {
                          name  = dimensions.value.name
                          value = dimensions.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

################################################################################
# Lifecycle Hooks
################################################################################

resource "aws_autoscaling_lifecycle_hook" "this" {
  for_each = { for hook in var.lifecycle_hooks : hook.name => hook }

  name                    = each.value.name
  autoscaling_group_name  = aws_autoscaling_group.this.name
  lifecycle_transition    = each.value.lifecycle_transition
  default_result          = each.value.default_result
  heartbeat_timeout       = each.value.heartbeat_timeout
  notification_target_arn = each.value.notification_target_arn
  role_arn                = each.value.role_arn
  notification_metadata   = each.value.notification_metadata
}

################################################################################
# Scheduled Actions
################################################################################

resource "aws_autoscaling_schedule" "this" {
  for_each = { for action in var.scheduled_actions : action.name => action }

  scheduled_action_name  = each.value.name
  autoscaling_group_name = aws_autoscaling_group.this.name
  min_size               = each.value.min_size
  max_size               = each.value.max_size
  desired_capacity       = each.value.desired_capacity
  start_time             = each.value.start_time
  end_time               = each.value.end_time
  recurrence             = each.value.recurrence
  time_zone              = each.value.time_zone
}

################################################################################
# Notifications
################################################################################

resource "aws_autoscaling_notification" "this" {
  count = var.notification_topic_arn != null ? 1 : 0

  group_names   = [aws_autoscaling_group.this.name]
  notifications = var.notification_types
  topic_arn     = var.notification_topic_arn
}
