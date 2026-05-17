# ==========================================
# TIER 1: APPLICATION LOAD BALANCER SECURITY GROUP
# ==========================================
resource "aws_security_group" "alb_sg" {
  name        = "main-alb-security-group"
  description = "Allows public internet traffic to access the ALB"
  vpc_id      = aws_vpc.main.id # Links directly to the VPC you created earlier

  # Inbound: Allow HTTP from anywhere
  ingress {
    description = "Allow HTTP web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow the ALB to send traffic anywhere downstream
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}

# ==========================================
# TIER 2: WEB / APPLICATION SERVER SECURITY GROUP
# ==========================================
resource "aws_security_group" "app_sg" {
  name        = "app-server-security-group"
  description = "Restricts traffic strictly to the ALB tier"
  vpc_id      = aws_vpc.main.id

  # Inbound: ONLY allow traffic coming directly from the ALB's security group
  ingress {
    description     = "Allow traffic exclusively from the ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # This is the golden security link
  }

  # Outbound: Allow servers to fetch updates from internet (via NAT Gateway)
  egress {
    description = "Allow outbound updates"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-server-security-group"
  }
}

# ==========================================
# TIER 3: DATABASE SECURITY GROUP
# ==========================================
resource "aws_security_group" "db_sg" {
  name        = "database-security-group"
  description = "Isolates database to only accept application requests"
  vpc_id      = aws_vpc.main.id

  # Inbound: ONLY allow traffic coming from the App Server's security group
  ingress {
    description     = "Allow database access exclusively from App Tier"
    from_port       = 3306 # Standard port for MySQL / Aurora RDS
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] # Deep isolation link
  }

  # Outbound: Databases shouldn't talk to the internet freely
  egress {
    description = "Restrict outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database-security-group"
  }
}
