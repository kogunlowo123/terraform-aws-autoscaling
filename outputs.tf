################################################################################
# Launch Template
################################################################################

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.this.id
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value       = aws_launch_template.this.arn
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = aws_launch_template.this.latest_version
}

################################################################################
# Auto Scaling Group
################################################################################

output "autoscaling_group_id" {
  description = "The ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.id
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "autoscaling_group_min_size" {
  description = "The minimum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.min_size
}

output "autoscaling_group_max_size" {
  description = "The maximum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.max_size
}

output "autoscaling_group_desired_capacity" {
  description = "The number of EC2 instances that should be running in the group"
  value       = aws_autoscaling_group.this.desired_capacity
}

output "autoscaling_group_vpc_zone_identifier" {
  description = "The VPC zone identifier"
  value       = aws_autoscaling_group.this.vpc_zone_identifier
}

output "autoscaling_group_availability_zones" {
  description = "The availability zones of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.availability_zones
}

################################################################################
# Scaling Policies
################################################################################

output "scaling_policy_arns" {
  description = "Map of scaling policy names to their ARNs"
  value       = { for k, v in aws_autoscaling_policy.this : k => v.arn }
}

################################################################################
# Lifecycle Hooks
################################################################################

output "lifecycle_hook_names" {
  description = "List of lifecycle hook names"
  value       = [for k, v in aws_autoscaling_lifecycle_hook.this : v.name]
}

################################################################################
# Scheduled Actions
################################################################################

output "scheduled_action_arns" {
  description = "Map of scheduled action names to their ARNs"
  value       = { for k, v in aws_autoscaling_schedule.this : k => v.arn }
}
