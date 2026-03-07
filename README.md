# terraform-aws-autoscaling

Terraform module to create AWS Auto Scaling Groups with support for advanced features including predictive scaling, warm pools, lifecycle hooks, mixed instances policies, instance refresh, scheduled actions, and notifications.

## Features

- **Launch Template** - Configurable launch template with IAM instance profiles, monitoring, and user data
- **Mixed Instances Policy** - Support for multiple instance types with on-demand/spot allocation strategies
- **Warm Pool** - Pre-initialized instances for faster scaling with configurable pool state
- **Predictive Scaling** - ML-driven scaling using predefined or custom metrics
- **Target Tracking Scaling** - Automatic scaling to maintain a target metric value
- **Step Scaling** - Scaling adjustments based on alarm thresholds
- **Lifecycle Hooks** - Custom actions during instance launch and termination
- **Instance Refresh** - Rolling deployments with checkpointing and auto-rollback
- **Scheduled Actions** - Time-based scaling for predictable traffic patterns
- **Instance Maintenance Policy** - Control healthy instance percentages during updates
- **SNS Notifications** - Alerts for scaling events and errors

## Usage

### Basic

```hcl
module "autoscaling" {
  source = "github.com/kogunlowo123/terraform-aws-autoscaling"

  name       = "my-asg"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-abc123", "subnet-def456"]

  image_id      = "ami-0123456789abcdef0"
  instance_type = "t3.micro"

  min_size         = 1
  max_size         = 3
  desired_capacity = 2
}
```

### Advanced with Mixed Instances and Predictive Scaling

```hcl
module "autoscaling" {
  source = "github.com/kogunlowo123/terraform-aws-autoscaling"

  name       = "advanced-asg"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-abc123", "subnet-def456"]

  image_id      = "ami-0123456789abcdef0"
  instance_type = "t3.medium"

  min_size = 2
  max_size = 10

  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "lowest-price"
    }
    override = [
      { instance_type = "t3.medium" },
      { instance_type = "t3a.medium" },
      { instance_type = "m5.large" },
    ]
  }

  warm_pool = {
    pool_state = "Hibernated"
    min_size   = 1
  }

  scaling_policies = [
    {
      name        = "predictive-scaling"
      policy_type = "PredictiveScaling"
      predictive = {
        mode = "ForecastAndScale"
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
}
```

## Examples

- [Basic](examples/basic/) - Simple ASG with minimal configuration
- [Advanced](examples/advanced/) - Mixed instances, warm pool, lifecycle hooks, and predictive scaling
- [Complete](examples/complete/) - Full-featured configuration with all options demonstrated

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.20.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name for the ASG and related resources | `string` | n/a | yes |
| vpc\_id | VPC ID for deployment | `string` | n/a | yes |
| subnet\_ids | List of subnet IDs | `list(string)` | n/a | yes |
| image\_id | AMI ID for the launch template | `string` | n/a | yes |
| instance\_type | EC2 instance type | `string` | `"t3.medium"` | no |
| min\_size | Minimum ASG size | `number` | `1` | no |
| max\_size | Maximum ASG size | `number` | `3` | no |
| desired\_capacity | Desired instance count | `number` | `null` | no |
| health\_check\_type | Health check type (EC2 or ELB) | `string` | `"EC2"` | no |
| health\_check\_grace\_period | Grace period in seconds | `number` | `300` | no |
| target\_group\_arns | Target group ARNs | `list(string)` | `[]` | no |
| mixed\_instances\_policy | Mixed instances configuration | `object` | `null` | no |
| warm\_pool | Warm pool configuration | `object` | `null` | no |
| instance\_refresh | Instance refresh configuration | `object` | `null` | no |
| lifecycle\_hooks | Lifecycle hook configurations | `list(object)` | `[]` | no |
| scaling\_policies | Scaling policy configurations | `list(object)` | `[]` | no |
| scheduled\_actions | Scheduled action configurations | `list(object)` | `[]` | no |
| instance\_maintenance\_policy | Maintenance policy configuration | `object` | `null` | no |
| user\_data | Base64-encoded user data | `string` | `null` | no |
| key\_name | EC2 key pair name | `string` | `null` | no |
| security\_group\_ids | Security group IDs | `list(string)` | `[]` | no |
| iam\_instance\_profile\_arn | IAM instance profile ARN | `string` | `null` | no |
| enable\_monitoring | Enable detailed monitoring | `bool` | `true` | no |
| tags | Resource tags | `map(string)` | `{}` | no |
| propagate\_tags\_at\_launch | Propagate tags to instances | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| autoscaling\_group\_id | ASG ID |
| autoscaling\_group\_name | ASG name |
| autoscaling\_group\_arn | ASG ARN |
| launch\_template\_id | Launch template ID |
| launch\_template\_arn | Launch template ARN |
| scaling\_policy\_arns | Map of scaling policy ARNs |
| lifecycle\_hook\_names | List of lifecycle hook names |
| scheduled\_action\_arns | Map of scheduled action ARNs |

## License

MIT Licensed. See [LICENSE](LICENSE) for full details.
