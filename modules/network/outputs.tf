output "vpc_id" {
  description = "vpcのID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "vpcで扱うcide_block"
  value       = aws_vpc.this.cidr_block
}

output "public_subnets" {
  description = "public-subnetのlist"
  value       = aws_subnet.public
}

output "private_subnets" {
  description = "private-subnetのlist"
  value       = aws_subnet.private
}
