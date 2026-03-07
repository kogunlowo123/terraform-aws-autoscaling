locals {
  name = var.name

  use_mixed_instances_policy = var.mixed_instances_policy != null

  tags = merge(
    var.tags,
    {
      "Name"      = local.name
      "ManagedBy" = "terraform"
    }
  )

  asg_tags = [
    for key, value in local.tags : {
      key                 = key
      value               = value
      propagate_at_launch = var.propagate_tags_at_launch
    }
  ]

  # Build a map of scaling policies by name for easy reference
  scaling_policies_map = {
    for policy in var.scaling_policies : policy.name => policy
  }

  # Build a map of lifecycle hooks by name
  lifecycle_hooks_map = {
    for hook in var.lifecycle_hooks : hook.name => hook
  }

  # Build a map of scheduled actions by name
  scheduled_actions_map = {
    for action in var.scheduled_actions : action.name => action
  }
}
