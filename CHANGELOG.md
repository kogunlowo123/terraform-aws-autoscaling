# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-07

### Added

- Initial release of the terraform-aws-autoscaling module
- Auto Scaling Group with configurable launch template
- Mixed instances policy with on-demand and spot allocation strategies
- Warm pool support with configurable pool state, min size, and max prepared capacity
- Predictive scaling policies with predefined and custom metric specifications
- Target tracking scaling policies with predefined and custom metrics
- Step scaling policies with configurable step adjustments
- Lifecycle hooks for instance launching and terminating events
- Instance refresh with rolling strategy, checkpointing, and auto-rollback
- Scheduled actions for time-based scaling
- Instance maintenance policy configuration
- SNS notification support for scaling events
- Basic, advanced, and complete usage examples
