
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"

}

# This will create a S.G without any rules. Next part is to add the rules. 
# For creating inbound and outbound rules, we have diff resource type

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  #from_port         = 0
  ip_protocol       = "-1"  # All protocols
  #to_port           = 0
}


resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}