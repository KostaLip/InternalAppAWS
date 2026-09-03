resource "aws_security_group" "vpn-instance-sg" {
  vpc_id = aws_vpc.vpn-vpc.id
  description = "Security group for VPN Instance"

  tags = {
    "Name" = "vpn-instance-sg"
  }
}

locals  {
    vpn-rules = {
        dns_tcp = { port = 53, protocol = "tcp", cidr = "10.0.0.0/24", desc = "DNS (TCP)" }
        dns_udp = { port = 53, protocol = "udp", cidr = "10.0.0.0/24", desc = "DNS (UDP)" }
        kerberos_tcp = { port = 88, protocol = "tcp", cidr = "10.0.0.0/24", desc = "Kerberos (TCP)" }
        kerberos_udp = { port = 88, protocol = "udp", cidr = "10.0.0.0/24", desc = "Kerberos (UDP)" }
        kpasswd_tcp = { port = 464, protocol = "tcp", cidr = "10.0.0.0/24", desc = "Kpasswd (TCP)" }
        kpasswd_udp = { port = 464, protocol = "udp", cidr = "10.0.0.0/24", desc = "Kpasswd (UDP)" }
        ldap_tcp = { port = 389, protocol = "tcp", cidr = "10.0.0.0/24", desc = "LDAP (TCP)" }
        ldap_udp = { port = 389, protocol = "udp", cidr = "10.0.0.0/24", desc = "LDAP (UDP)" }
        ldap_gc = { port = 3268, protocol = "tcp", cidr = "10.0.0.0/24", desc = "LDAP GC" }
        ldap_gc_ssl = { port = 3269, protocol = "tcp", cidr = "10.0.0.0/24", desc = "LDAP GC SSL" }
        smb = { port = 445, protocol = "tcp", cidr = "10.0.0.0/24", desc = "SMB" }
        rpc = { port = 135, protocol = "tcp", cidr = "10.0.0.0/24", desc = "RPC Endpoint Mapper" }
        ntp = { port = 123, protocol = "udp", cidr = "10.0.0.0/24", desc = "NTP" }
        ssh = { port = 22, protocol = "tcp", cidr = "0.0.0.0/0", desc = "SSH" }
        openvpn = { port = 1194, protocol = "udp", cidr = "0.0.0.0/0", desc = "OpenVPN tunnel" }
    }

    vpn-range-rules = {
        rpc_dynamic = { from = 49152, to = 65535, protocol = "tcp", cidr = "10.0.0.0/24", desc = "RPC dynamic range" }
    }
}

locals {
  compute-vpc-rules = {
    dns-tcp-compute = { port = 53,   protocol = "tcp", desc = "DNS from Compute VPC (TCP)" }
    dns-udp-compute = { port = 53,   protocol = "udp", desc = "DNS from Compute VPC (UDP)" }
    postgres-compute = { port = 5432, protocol = "tcp", desc = "Postgres from Compute VPC" }
    ldap-tcp-compute = { port = 389,  protocol = "tcp", desc = "LDAP from Compute VPC" }
    ldap-udp-compute = { port = 389,  protocol = "udp", desc = "LDAP from Compute VPC (UDP)" }
    kerberos-tcp-compute = { port = 88,   protocol = "tcp", desc = "Kerberos from Compute VPC" }
    kerberos-udp-compute = { port = 88,   protocol = "udp", desc = "Kerberos from Compute VPC (UDP)" }
    smb-compute = { port = 445,  protocol = "tcp", desc = "SMB from Compute VPC" }
    rpc-compute = { port = 135,  protocol = "tcp", desc = "RPC from Compute VPC" }
    ldap-gc-compute = { port = 3268, protocol = "tcp", desc = "LDAP GC from Compute VPC" }
  }
  range-rules = {
    rpc_dynamic = { from = 49152, to = 65535, protocol = "tcp", cidr = "10.0.0.0/24", desc = "RPC dynamic range" }
  }
}

resource "aws_security_group_rule" "compute-vpc-rules" {
  for_each = local.compute-vpc-rules

  type = "ingress"
  from_port = each.value.port
  to_port = each.value.port
  protocol = each.value.protocol
  cidr_blocks = ["10.0.0.0/24"]
  security_group_id = aws_security_group.vpn-instance-sg.id
  description = each.value.desc
}

resource "aws_security_group_rule" "vpn-rules" {
  for_each = local.vpn-rules

  type = "ingress"
  from_port = each.value.port
  to_port = each.value.port
  protocol = each.value.protocol
  cidr_blocks = [each.value.cidr]
  security_group_id = aws_security_group.vpn-instance-sg.id
  description = each.value.desc
}

resource "aws_security_group_rule" "vpn-range-rules" {
  for_each = local.vpn-range-rules

  type = "ingress"
  from_port = each.value.from
  to_port = each.value.to
  protocol = each.value.protocol
  cidr_blocks = [ each.value.cidr ]
  security_group_id = aws_security_group.vpn-instance-sg.id
  description = each.value.desc
}

resource "aws_security_group_rule" "range-rules" {
  for_each = local.range-rules

  type = "ingress"
  from_port = each.value.from
  to_port = each.value.to
  protocol = each.value.protocol
  cidr_blocks = [ each.value.cidr ]
  security_group_id = aws_security_group.vpn-instance-sg.id
  description = each.value.desc
}

resource "aws_security_group_rule" "vpn-ping" {
  type = "ingress"
  from_port = -1
  to_port = -1
  protocol = "icmp"
  cidr_blocks = [ "10.0.0.0/24" ]
  security_group_id = aws_security_group.vpn-instance-sg.id
}

resource "aws_security_group_rule" "compute-ping" {
  type = "ingress"
  from_port = -1
  to_port = -1
  protocol = "icmp"
  cidr_blocks = [ "10.1.0.0/16" ]
  security_group_id = aws_security_group.vpn-instance-sg.id
}

resource "aws_security_group_rule" "vpn-instance-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpn-instance-sg.id
}