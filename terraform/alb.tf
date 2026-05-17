# ==========================================
# 1. THE BRAIN: APPLICATION LOAD BALANCER
# ==========================================
resource "aws_lb" "main_alb" {
  name               = "main-application-load-balancer"
  internal           = false # False makes it public-facing to accept internet traffic
  load_balancer_type = "application"
  
  # Attach the ALB Security Group we created in step 1
  security_groups    = [aws_security_group.alb_sg.id]
  
  # Deploys the ALB endpoints across your PUBLIC subnets for high availability
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "main-alb"
  }
}

# ==========================================
# 2. THE ROUTING TARGET: ALB TARGET GROUP
# ==========================================
resource "aws_lb_target_group" "app_tg" {
  name     = "app-instances-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Health Check Configuration: Continuously pings the web servers
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200" # Expects a standard "OK" response
    interval            = 30    # Checks every 30 seconds
    timeout             = 5     # Drops connection if no reply in 5 seconds
    healthy_threshold   = 2     # Marks healthy after 2 successful checks
    unhealthy_threshold = 2     # Pulls out of rotation after 2 failures
  }
}

# ==========================================
# 3. THE RECEPTIONIST: ALB LISTENER
# ==========================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # By default, forward all incoming web traffic straight to our target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ==========================================
# 4. THE CONNECTION: ATTACH ASG TO THE TARGET GROUP
# ==========================================
# This links your Auto Scaling Group directly to the Load Balancer
resource "aws_autoscaling_attachment" "asg_attachment_alb" {
  autoscaling_group_name = aws_autoscaling_group.app_asg.id
  lb_target_group_arn   = aws_lb_target_group.app_tg.arn
}
