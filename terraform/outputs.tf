output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The assigned ID of the production VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of IDs for the public edge subnets"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of IDs for the private application subnets"
}