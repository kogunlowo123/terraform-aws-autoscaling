output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_arn
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = module.autoscaling.launch_template_id
}

output "scaling_policy_arns" {
  description = "Map of scaling policy names to their ARNs"
  value       = module.autoscaling.scaling_policy_arns
}

output "scheduled_action_arns" {
  description = "Map of scheduled action names to their ARNs"
  value       = module.autoscaling.scheduled_action_arns
}

output "lifecycle_hook_names" {
  description = "List of lifecycle hook names"
  value       = module.autoscaling.lifecycle_hook_names
}
