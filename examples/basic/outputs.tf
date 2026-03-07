output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_arn
}
