
resource "aws_ebs_volume" "myebs" {
  count = 2
  availability_zone = element(aws_instance.ec2_instance.*.availability_zone, count.index)
  size              = 30
  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  count = 2
  device_name = "/dev/sdh"
  volume_id   = element(aws_ebs_volume.myebs.*.id, count.index)
  instance_id = element(aws_instance.ec2_instance.*.id, count.index)
}

/*

The Terraform plan states:

EBS Volumes:

aws_ebs_volume.myebs[0] must be replaced due to a change in the availability zone.
aws_ebs_volume.myebs[1] will be created in us-east-1b.

Volume Attachments:

aws_volume_attachment.ebs_att[0] will be created to attach the first volume to the first instance.
aws_volume_attachment.ebs_att[1] will be created to attach the second volume to the second instance.

*/
