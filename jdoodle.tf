provider "aws" {
  region = "us-west-2"
}

resource "random_pet" "this" {
  length = 2
}

resource "aws_launch_template" "aws_autoscale_conf" {
  name = "jdoodle_config"
  image_id = "ami-008fe2fc65df48dac"
  instance_type = "t2.micro"
  key_name = "master_server_us-west-2"
  monitoring {
    enabled = true
  }
}

resource "aws_autoscaling_group" "jdoodle_group" {
  availability_zones = ["us-west-2a"]
  name = "autoscalinggroup"
  max_size = 5
  min_size = 2
  health_check_grace_period = 30
  health_check_type = "EC2"
  force_delete = true
  termination_policies = ["OldestInstance"]
  instance_refresh {
    strategy = "Rolling"
    preferences {
      instance_warmup = 300
      min_healthy_percentage = 90
    }
    triggers = ["tag", "desired_capacity"/*, "launch_template"*/] 
  }
  launch_template {
    id = aws_launch_template.aws_autoscale_conf.id
    version = aws_launch_template.aws_autoscale_conf.latest_version
  }
}

resource "aws_autoscaling_schedule" "jdoodle_schedule" {
  scheduled_action_name = "autoscalegroup_action"
  min_size = 2
  max_size = 5
  desired_capacity = 2
  start_time = "2024-01-22T11:00:00Z"
  recurrence = "00 00 * * *"
  autoscaling_group_name = aws_autoscaling_group.jdoodle_group.name
}

resource "aws_autoscaling_policy" "jdoodle_policy" {
  name = "autoscalegroup_policy"
  estimated_instance_warmup = 180
  autoscaling_group_name = aws_autoscaling_group.jdoodle_group.name
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  } 
} 

/*
resource "aws_autoscaling_policy" "jdoodle_policy" {
  autoscaling_group_name = aws_autoscaling_group.jdoodle_group.name
  name                   = "autoscalegroup_policy"
  policy_type            = "PredictiveScaling"
  predictive_scaling_configuration {
    metric_specification {
      target_value = 10
      customized_load_metric_specification {
        metric_data_queries {
          id         = "load_sum"
          expression = "SUM(SEARCH('{AWS/EC2, autoscaling_group_name} MetricName=\"CPUUtilization\" jdoodle_group', 'Sum', 3600))"
        }
      }
      customized_capacity_metric_specification {
        metric_data_queries {
          id         = "capacity_sum"
          expression = "SUM(SEARCH('{AWS/AutoScaling, autoscaling_group_name} MetricName=\"GroupInServiceIntances\" jdoodle_group', 'Average', 300))"
        }
      }
      customized_scaling_metric_specification {
        metric_data_queries {
          id          = "capacity_sum"
          expression  = "SUM(SEARCH('{AWS/AutoScaling,autoscaling_group_name} MetricName=\"GroupInServiceIntances\" jdoodle_group', 'Average', 300))"
          return_data = false
        }
        metric_data_queries {
          id          = "load_sum"
          expression  = "SUM(SEARCH('{AWS/EC2,autoscaling_group_name} MetricName=\"CPUUtilization\" jdoodle_group', 'Sum', 300))"
          return_data = false
        }
        metric_data_queries {
          id         = "weighted_average"
          expression = "load_sum / (capacity_sum * PERIOD(capacity_sum) / 60)"
        }
      }
    }
  }
}
*/

resource "aws_cloudwatch_metric_alarm" "jdoodle_cpu_alarm_up" {
  alarm_name = "jdoodle_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "LoadAverage"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "75"
  alarm_actions = [
    "${aws_autoscaling_policy.jdoodle_policy.arn}"
    ]
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.jdoodle_group.name}"
  }
}

resource "aws_sns_topic" "myasg_sns_topic" {
  name = "myasg-sns-topic-${random_pet.this.id}"
}

## SNS - Subscription
resource "aws_sns_topic_subscription" "myasg_sns_topic_subscription" {
  topic_arn = aws_sns_topic.myasg_sns_topic.arn
  protocol  = "email"
  endpoint  = "shishakt.patna@gmail.com"
}

## Create Autoscaling Notification Resource
resource "aws_autoscaling_notification" "myasg_notifications" {
  group_names = [aws_autoscaling_group.jdoodle_group.id]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
  topic_arn = aws_sns_topic.myasg_sns_topic.arn 
}
