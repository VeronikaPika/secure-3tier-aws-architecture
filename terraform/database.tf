# ==========================================
# 1. DATABASE SUBNET GROUP (WHERE IT LIVES)
# ==========================================
# Managed databases require a group of subnets across different AZs 
# so AWS can failover to a backup database if a data center goes down.
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "main-db-subnet-group"
  description = "Database subnet group spanning multiple availability zones"
  
  # Links to your isolated database subnets from your network setup
  subnet_ids  = [aws_subnet.database[0].id, aws_subnet.database[1].id]

  tags = {
    Name = "main-db-subnet-group"
  }
}

# ==========================================
# 2. THE STORAGE PILLAR: AMAZON RDS INSTANCE
# ==========================================
resource "aws_db_instance" "main_db" {
  identifier             = "production-3tier-database"
  allocated_storage      = 20               # 20 GB minimal allocation (Free-tier eligible)
  max_allocated_storage  = 100              # Allows auto-scaling storage if data grows
  engine                 = "mysql"
  engine_version         = "8.0"            # Standard enterprise stable version
  instance_class         = "db.t3.micro"    # Light, cost-effective type for portfolio use
  
  # Database Access Credentials
  db_name                = "application_db"
  username               = "admin_user"
  password               = "SuperSecurePassword2026!" # In production, use AWS Secrets Manager!
  
  # Network & Security Isolation
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id] # Attaches the strict DB firewall
  skip_final_snapshot    = true             # Allows smooth 'terraform destroy' later without hangs
  publicly_accessible    = false            # CRITICAL: Ensures no public IP is attached to this DB

  tags = {
    Name = "production-database"
  }
}
