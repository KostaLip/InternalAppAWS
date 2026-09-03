data "aws_vpc" "ad-vpc" {
  filter {
    name = "tag:Name"
    values = ["vpn-vpc"]
  }
}

data "aws_subnet" "ad-subnet-a" {
  filter {
    name = "tag:Name"
    values = ["public-vpn-ad-connector-subnet"]
  }
}

data "aws_subnet" "ad-subnet-b" {
  filter {
    name = "tag:Name"
    values = ["public-ad-connector-subnet"]
  }
}

resource "aws_directory_service_directory" "ad-connector" {
  name = "lab.local"
  type = "ADConnector"
  size = "Small"

  connect_settings {
    customer_dns_ips = ["10.8.0.2"]
    customer_username = "Administrator"
    subnet_ids = [
        data.aws_subnet.ad-subnet-a.id,
        data.aws_subnet.ad-subnet-b.id
    ]

    vpc_id = data.aws_vpc.ad-vpc.id
  }

  password = var.password

  tags = {
    "Name" = "AD connector"
  }
}