# 1. Fetch the available Availability Zones in our London region dynamically
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. Create the Primary Enterprise VPC (Our isolated data center playground)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "Enterprise-VPC"
    Environment = "Production"
  }
}

# 3. Create Public Subnets (Edge Layer / Where the Application Load Balancer lives)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-Edge-${count.index + 1}"
  }
}

# 4. Create Private Subnets (Compute Layer / Where the C#/.NET web servers live)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Private-Subnet-App-${count.index + 1}"
  }
}

# 5. Create Isolated Subnets (Data Layer / Where the SQL Server Database lives)
resource "aws_subnet" "database" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Isolated-Subnet-DB-${count.index + 1}"
  }
}

# 6. Internet Gateway (The front door for public web traffic to enter the VPC)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main-Internet-Gateway"
  }
}

# 7. Public Route Table (Tells public subnets how to route traffic out to the internet)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# 8. Associate Public Subnets with the Public Route Table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}