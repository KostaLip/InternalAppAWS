resource "aws_internet_gateway" "vpn-igw" {
  vpc_id = aws_vpc.vpn-vpc.id

  tags = {
    "Name" = "vpn-igw"
  }
}