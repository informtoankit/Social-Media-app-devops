resource "aws_eip" "nat" {
  count  = var.nat_gateway_count
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}"
  }

  depends_on = [var.internet_gateway_id]
}
