
# when i am creating a EC2 instance with help of terraform like this - 

resource "aws_instance" "ec2_instance" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  count = 2

  tags = {
    Name = "dev"
  }
}

What happens to the vpc and SG in which this gets created? like if i dont provide vpc, and Security group, will it take the default vpc? what if i want to give S.G that allows all traffic for inbound and outbound?

# Sol

When you create an EC2 instance using Terraform without specifying a VPC or security group, it will be created in the default VPC of the specified region. Here’s how it works and how you can customize the VPC and security group settings:

### Default Behavior

- **VPC:** If no VPC is specified, the instance will be launched in the default VPC of the region.
- **Security Group:** If no security group is specified, the instance will be associated with the default security group of the default VPC. The default security group allows all inbound traffic from other instances in the same security group and allows all outbound traffic.

### Specifying a Security Group

To create a security group that allows all inbound and outbound traffic and associate it with your EC2 instances, you need to define the security group and then reference it in your EC2 instance resource.

### Example Terraform Configuration

```hcl
provider "aws" {
  region = "us-west-2"  # Specify your region
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all_traffic"
  description = "Security group that allows all inbound and outbound traffic"
  vpc_id      = "vpc-12345678"  # Replace with your VPC ID

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  count         = 2

  vpc_security_group_ids = [aws_security_group.allow_all.id]  # Referencing the security group

  tags = {
    Name = "dev"
  }
}
```

### Steps to Customize VPC and Security Group

1. **Define the Security Group:**
   - Create a security group that allows all inbound and outbound traffic.
   - Specify the `vpc_id` to ensure it is created in the desired VPC.

2. **Reference the Security Group in EC2 Instance:**
   - Use `vpc_security_group_ids` to associate the EC2 instances with the created security group.

### Creating a New VPC (Optional)

If you want to create a new VPC and use it, you can define it in your Terraform configuration:

```hcl
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all_traffic"
  description = "Security group that allows all inbound and outbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  count         = 2

  subnet_id              = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name = "dev"
  }
}
```

This configuration includes creating a new VPC, subnet, security group, and then launching the EC2 instances within this setup. Adjust the CIDR blocks and availability zones as per your requirements.