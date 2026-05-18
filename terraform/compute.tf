# ==========================================
# 1. FETCH THE LATEST CLEAN AMAZON LINUX AMI
# ==========================================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# ==========================================
# 2. THE BLUEPRINT: AWS LAUNCH TEMPLATE
# ==========================================
resource "aws_launch_template" "app_template" {
  name_prefix   = "main-app-template-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro" # Free-tier friendly, perfect for demonstration

  # Attach the Web/App security group we built earlier
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Metadata Options: Enforce IMDSv2 for high enterprise security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # User Data: Automates a mini-webserver setup upon startup
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from the Secure Multi-AZ App Tier</h1>" > /var/www/html/index.html
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# 3. THE ENGINE: AUTO SCALING GROUP
# ==========================================
resource "aws_autoscaling_group" "app_asg" {
  name_prefix       = "main-app-asg-"
  desired_capacity  = 2                             # Deploys 2 servers out of the box for high availability
  max_size          = 4                             # Can scale up to 4 if a server gets hit hard
  min_size          = 1                             # Keeps at least 1 running to prevent downtime
  target_group_arns = [aws_lb_target_group.app.arn] #

  # Targets your PRIVATE subnets explicitly so these instances stay hidden
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  # Connects the ASG to our blueprint template
  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }

  # Health Checks: If an EC2 instance behaves weirdly, AWS replaces it immediately
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "app-tier-instance"
    propagate_at_launch = true
  }
}
