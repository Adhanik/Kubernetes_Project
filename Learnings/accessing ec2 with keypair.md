
To access your EC2 instance via SSH using the key pair, you need to follow these steps:

1. **Ensure you have the private key** that corresponds to the key pair you specified in your Terraform configuration.
2. **Retrieve the public IP address** of your EC2 instance.
3. **Use the SSH command** to connect to your EC2 instance.

Here’s how you can do this step-by-step:

### Step 1: Ensure You Have the Private Key

When you create a key pair, you get a private key file (e.g., `my-key-pair.pem`). Ensure you have this file on your local machine and it is accessible.

### Step 2: Retrieve the Public IP Address

You can retrieve the public IP address of your EC2 instance either from the AWS Management Console or via the Terraform output.

#### Retrieving Public IP from Terraform Output

Make sure your Terraform configuration includes an output for the public IP addresses:

```hcl
output "public_ips" {
  value = [for instance in aws_instance.ec2_instance : instance.public_ip]
}
```

After running `terraform apply`, you will see the public IP addresses in the output.

### Step 3: Use the SSH Command

Use the `ssh` command to connect to your EC2 instance. The basic syntax is:

```sh
ssh -i path/to/your-private-key.pem ec2-user@public-ip
```
ssh -i mykeypair.pem ec2-user@18.234.148.162

Replace `path/to/your-private-key.pem` with the path to your private key file and `public-ip` with the actual public IP address of your EC2 instance.

### Example

Assuming your private key file is `my-key-pair.pem` and the public IP address of your EC2 instance is `3.123.456.78`:

```sh
ssh -i ~/path/to/my-key-pair.pem ec2-user@3.123.456.78
```

### Important Notes:

- **File Permissions:** Ensure that your private key file has the correct permissions. If the permissions are too open, SSH will refuse to use the key. Set the permissions to read-only for your user:

  ```sh
  chmod 400 ~/path/to/my-key-pair.pem
  ```

- **Default Usernames:** The default username varies based on the AMI you are using:
  - For Amazon Linux AMIs: `ec2-user`
  - For Ubuntu AMIs: `ubuntu`
  - For CentOS AMIs: `centos`
  - For Debian AMIs: `admin` or `root`
  - For Red Hat AMIs: `ec2-user` or `root`

  Adjust the username in the `ssh` command accordingly.

### Full Example Configuration

Here is the complete example configuration including the key pair creation, EC2 instance, and output:

```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "my-generated-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Path to your public key file
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Security group that allows TLS traffic"
  vpc_id      = "vpc-12345678"  # Replace with your VPC ID

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  instance_name = ["jenkins", "ansible"]
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  count = 2

  key_name = aws_key_pair.generated_key.key_name  # Reference the key pair created

  tags = {
    Name = local.instance_name[count.index]
  }

  vpc_security_group_ids = [aws_security_group.allow_tls.id]
}

output "public_ips" {
  value = [for instance in aws_instance.ec2_instance : instance.public_ip]
}
```

Run `terraform apply` to create the resources and get the public IP addresses. Use the `ssh` command with the retrieved public IP addresses to connect to your instances.