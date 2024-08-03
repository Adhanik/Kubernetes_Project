
locals {
 instancename = ["jenkins", "ansible"]
}

resource "aws_instance" "ec2_instance" {
  ami = "ami-06c68f701d8090592"
  instance_type = var.instance_type
  count = 2
  key_name = "mykeypair"
  tags = {
    Name = local.instancename[count.index]
    }
vpc_security_group_ids = [aws_security_group.allow_tls.id]

}



resource "aws_instance" "ec2_kube" {
  ami = "ami-06c68f701d8090592"
  instance_type = "t2.medium"
  count = 1
  key_name = "mykeypair"
    tags = {
    Name = "kube"
    }
vpc_security_group_ids = [aws_security_group.allow_tls.id]
}

/* The below code can be used to spin up all the 3 Instances at once. 
NOTE - The t2.medium instance consume charges on hourly basis, so if you dont want to incur charges, use the resources 
mentioned above to create EC2 Instances. The kube EC2 should be created only when necessary, and can be deleted later without
the need to delete other t2.micro instances

locals {
  instance_name = {"jenkins": "t2.micro",
  "ansible": "t2.micro",
  "kube":"t2.medium"}
}
resource "aws_instance" "ec2_instance" {
  ami           = "ami-06c68f701d8090592"
  for_each = local.instance_name
  instance_type = each.value

  tags = {
    Name =each.key
  }

  key_name = "mykeypair"

  vpc_security_group_ids = [aws_security_group.allow_tls.id]
}
*/