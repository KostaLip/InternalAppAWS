resource "aws_security_group" "resolver-endpoint" {
  provider = aws.management
  name = "resolver-outbound-sg"
  vpc_id = data.aws_vpc.vpn-vpc.id

  egress {
    from_port = 53
    to_port = 53
    protocol = "tcp"
    cidr_blocks = ["10.8.0.0/24"]
  }

  egress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["10.8.0.0/24"]
  }
}

resource "aws_route53_resolver_endpoint" "outbound" {
  provider = aws.management
  name = "outbound-to-dc1"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.resolver-endpoint.id]

  ip_address {
    subnet_id = data.aws_subnet.subnet-a.id
  }

  ip_address {
    subnet_id = data.aws_subnet.subnet-b.id
  }
}

resource "aws_route53_resolver_rule" "lab-local-forward" {
  provider = aws.management
  domain_name = "lab.local"
  name = "forward-lab-local-to-dc1"
  rule_type = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  target_ip {
    ip = "10.8.0.2"
    port = 53
  }
}

resource "aws_route53_resolver_rule_association" "lab-local-vpc" {
  provider = aws.management
  resolver_rule_id = aws_route53_resolver_rule.lab-local-forward.id
  vpc_id = data.aws_vpc.vpn-vpc.id
}