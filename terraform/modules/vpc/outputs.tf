output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnets" {
  value = [
    for k, v in aws_subnet.private : v.id
  ]
}

output "public_subnets" {
  value = [
    for k, v in aws_subnet.public : v.id
  ]
}
