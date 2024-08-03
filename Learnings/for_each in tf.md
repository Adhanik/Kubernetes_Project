
So I want to create 2 ec2 instances with t2.micro, and one ec2 with t2.medium. We were doing it like this -->

locals {
  instance_name = ["jenkins", "ansible"]
}
resource "aws_instance" "ec2_instance" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  count = 2

  tags = {
    Name = local.instance_name[count.index]
  }

  key_name = "mykeypair"

  vpc_security_group_ids = [aws_security_group.allow_tls.id]
}

# for 3rd resource - 

locals {
  instance_name = ["kube"]
}
resource "aws_instance" "ec2_instance" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.medium"
  count = 1

  tags = {
    Name = local.instance_name[count.index]
  }

  key_name = "mykeypair"

  vpc_security_group_ids = [aws_security_group.allow_tls.id]
}

# could this be achieved using only one resource block?

# Sol - Yes, by making use of for_each

We can group the instance type along with their names in a key value pair format, and iterate over those to create this resources.

Refer to main.tf in EC2 folder on how we did this.

## Explaination for for_each

In Terraform, `for_each` is used to iterate over a collection (such as a map or a set) and create a resource for each element in that collection. This is similar to a `for` loop in other programming languages, but it is designed to work declaratively in Terraform's configuration language.

Here’s a step-by-step explanation of how `for_each` works:

1. **Defining the Collection**:
   The collection can be a map (dictionary) or a set. Each key-value pair (in case of a map) or each element (in case of a set) will be used to create a separate instance of the resource.

2. **Using `for_each`**:
   When you specify `for_each = local.instances`, Terraform will create a resource for each key-value pair in the `local.instances` map.

3. **Accessing Elements**:
   Within the resource block, you use `each.key` to access the key and `each.value` to access the value of the current element being iterated over. The keyword `each` is predefined in Terraform and cannot be changed to something like `i`.

Here’s a simple example to illustrate how `for_each` works:

### Example: Creating Multiple S3 Buckets

```hcl
locals {
  buckets = {
    bucket1 = "us-west-1"
    bucket2 = "us-east-1"
    bucket3 = "eu-west-1"
  }
}

resource "aws_s3_bucket" "example" {
  for_each = local.buckets

  bucket = each.key
  acl    = "private"

  tags = {
    Name        = each.key
    Environment = "Dev"
    Region      = each.value
  }
}
```

### Explanation

1. **Define the Collection**:
   ```hcl
   locals {
     buckets = {
       bucket1 = "us-west-1"
       bucket2 = "us-east-1"
       bucket3 = "eu-west-1"
     }
   }
   ```
   This map defines three buckets, each with a corresponding region.

2. **Use `for_each`**:
   ```hcl
   resource "aws_s3_bucket" "example" {
     for_each = local.buckets
   ```
   Terraform will create three S3 buckets, one for each key-value pair in the `local.buckets` map.

3. **Access Elements**:
   ```hcl
   bucket = each.key
   acl    = "private"
   
   tags = {
     Name        = each.key
     Environment = "Dev"
     Region      = each.value
   }
   ```
   - `each.key` is the name of the bucket.
   - `each.value` is the region where the bucket will be created.
   
This approach allows you to dynamically create multiple resources based on the collection's elements. 

### How `for_each` Works in Steps

1. **Initialize Collection**:
   ```hcl
   locals {
     instances = {
       jenkins = "t2.micro"
       ansible = "t2.micro"
       kube    = "t2.medium"
     }
   }
   ```

2. **Iterate Over Collection**:
   ```hcl
   resource "aws_instance" "ec2_instance" {
     for_each = local.instances
   ```
   - Terraform will iterate over `local.instances`.
   - For each iteration, it will take a key-value pair from the map.

3. **Create Resource for Each Element**:
   ```hcl
   ami           = "ami-06c68f701d8090592"
   instance_type = each.value

   tags = {
     Name = each.key
   }

   key_name = "mykeypair"
   vpc_security_group_ids = [aws_security_group.allow_tls.id]
   ```
   - For `jenkins = "t2.micro"`, it creates an instance with the name "jenkins" and type "t2.micro".
   - For `ansible = "t2.micro"`, it creates an instance with the name "ansible" and type "t2.micro".
   - For `kube = "t2.medium"`, it creates an instance with the name "kube" and type "t2.medium".

Using `for_each` in this way provides a powerful and flexible method to manage multiple resources in Terraform declaratively.