

resource "aws_instance" "ec2_instance" {
  ami           = "ami-06c68f701d8090592"

}

output "public-ip" {
    value = [for instance in aws_instance.ec2_instance : instance.public_ip]
}

Explanation
Output Block:

The output block named public_ips is defined to output the public IP addresses of all EC2 instances.
Instead of using count.index within the output block (which is not allowed), we use a for loop to iterate over each instance in the aws_instance.ec2_instance resource and collect their public IP addresses.
For Loop Syntax:

The syntax [for instance in aws_instance.ec2_instance : instance.public_ip] is used to create a list of public IP addresses. This loop iterates over each instance and extracts the public_ip attribute.