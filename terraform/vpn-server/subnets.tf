resource "aws_subnet" "public-vpn-ad-connector-subnet" {
  vpc_id = aws_vpc.vpn-vpc.id
  cidr_block = "10.0.0.0/28"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public-vpn-ad-connector-subnet"
  }
}

resource "aws_subnet" "public-ad-connector-subnet" {
  vpc_id = aws_vpc.vpn-vpc.id
  cidr_block = "10.0.0.16/28"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public-ad-connector-subnet"
  }
}