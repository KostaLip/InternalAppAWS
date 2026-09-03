resource "aws_instance" "vpn-instance" {
  ami = var.ami_id
  instance_type = var.vpn-instance-type
  subnet_id = aws_subnet.public-vpn-ad-connector-subnet.id
  vpc_security_group_ids = [ aws_security_group.vpn-instance-sg.id ]
  source_dest_check = false

  tags = {
    "Name" = "vpn-instance"
  }
}