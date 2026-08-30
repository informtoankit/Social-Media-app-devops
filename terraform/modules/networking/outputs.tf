output "nat_gateway_ids" {
  value = aws_nat_gateway.main[*].id
}

output "nat_gateway_ips" {
  value = aws_eip.nat[*].public_ip
}
