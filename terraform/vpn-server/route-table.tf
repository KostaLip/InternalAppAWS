resource "aws_route_table" "vpn-route-table" {
  vpc_id = aws_vpc.vpn-vpc.id

  tags = {
    "Name" = "vpn-route-table"
  }
}

resource "aws_route" "vpn-internet-route" {
  route_table_id = aws_route_table.vpn-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.vpn-igw.id
}

resource "aws_route" "vpn-server-client-route" {
  route_table_id = aws_route_table.vpn-route-table.id
  destination_cidr_block = "10.8.0.0/24"
  network_interface_id = aws_instance.vpn-instance.primary_network_interface_id
}

resource "aws_route_table_association" "vpn-public-rt-ass" {
  subnet_id = aws_subnet.public-ad-connector-subnet.id
  route_table_id = aws_route_table.vpn-route-table.id
}

resource "aws_route_table_association" "vpn-ad-public-rt-ass" {
  subnet_id = aws_subnet.public-vpn-ad-connector-subnet.id
  route_table_id = aws_route_table.vpn-route-table.id
}