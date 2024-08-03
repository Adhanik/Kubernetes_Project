

# Are ebs volumens by default attached to our EC2 instances. the below is our tf file from which we created 3 EC2 instances, no ebs is mentioned here. Can you help me understand this ebs, its functioning, why is it required and is it added by default to each EC2?

# Sol

### Understanding EBS (Elastic Block Store)

#### What is EBS?
EBS (Elastic Block Store) is a scalable, high-performance block storage service provided by AWS for use with EC2 instances. EBS volumes are essentially virtual hard drives that can be attached to your EC2 instances to store data. 

### Why is EBS Required?
- **Persistent Storage**: EBS volumes provide persistent storage, meaning the data remains intact even after the instance is stopped or restarted.
- **Performance**: EBS offers various volume types optimized for performance and cost, catering to different use cases like high I/O operations or sequential data access.
- **Backup and Restore**: EBS supports snapshots, which are backups of the volume that can be used to restore data or create new volumes.

### Default Behavior of EBS with EC2 Instances
When you launch an EC2 instance, AWS attaches a root EBS volume by default. This root volume contains the operating system and is used to boot the instance. Depending on the AMI (Amazon Machine Image) you use, the size and type of this volume can vary.

### Terraform and EBS
Even if you do not explicitly define an EBS volume in your Terraform configuration, AWS will attach a default root EBS volume to your EC2 instance.

Here's an example to illustrate this:

```hcl
locals {
  instances = {
    jenkins = "t2.micro"
    ansible = "t2.micro"
    kube    = "t2.medium"
  }
}

resource "aws_instance" "ec2_instance" {
  for_each = local.instances

  ami           = "ami-06c68f701d8090592"
  instance_type = each.value

  tags = {
    Name = each.key
  }

  key_name = "mykeypair"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
}
```

### Adding EBS Volumes Explicitly
If you want to add additional EBS volumes or customize the root volume, you can do so using the `ebs_block_device` and `root_block_device` blocks in your Terraform configuration.

#### Example with Additional EBS Volume

```hcl
locals {
  instances = {
    jenkins = "t2.micro"
    ansible = "t2.micro"
    kube    = "t2.medium"
  }
}

resource "aws_instance" "ec2_instance" {
  for_each = local.instances

  ami           = "ami-06c68f701d8090592"
  instance_type = each.value

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }

  ebs_block_device {
    device_name = "/dev/sdh"
    volume_type = "gp2"
    volume_size = 50
  }

  tags = {
    Name = each.key
  }

  key_name = "mykeypair"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
}
```

### Explanation
- **root_block_device**: This block customizes the root volume that contains the operating system.
- **ebs_block_device**: This block adds an additional EBS volume to the instance.

### Summary
- **Default Behavior**: AWS attaches a root EBS volume to each EC2 instance by default.
- **EBS Volumes**: Provide persistent storage and are essential for storing data and operating systems.
- **Customization**: You can customize the root volume and add additional volumes using Terraform configuration.

Understanding EBS and its default behavior helps you manage storage and costs effectively when working with EC2 instances.