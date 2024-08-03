
For logging into EC2 Instances, you need key pair. If you dont specify the key pair in your tf file, you will not be able to access the EC2.

When you create an EC2 instance using Terraform without specifying a key_name, the instance is created without an SSH key pair associated with it. This means that you will not be able to SSH into the instance using a key pair, as no key pair will be configured for that instance.


There are 2 ways to do this -

key_name
aws_key_pair


1. key_name - 
    
    a. Manually create a key pair from EC2 console
    b. In the tf file, in ec2 resource block, pass the key name which you have created.
    c. Access the resource.

2. aws_key_pair

    a. This involves you generating your own key pair directly and manage it with TF
    b. Generate your keypair using - ssh-keygen -t rsa -b 4096 -C "your_email@example.com"


# Create a new key pair
resource "aws_key_pair" "generated_key" {
  key_name   = "my-generated-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Path to your public key file
}



### Explanation

1. **Creating the Key Pair:**
   - The `aws_key_pair` resource is used to create a new key pair in AWS. The `public_key` attribute should point to your existing public key file (e.g., `~/.ssh/id_rsa.pub`).
   - If you don't have a key pair, you can generate one using `ssh-keygen`:
     ```sh
     ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
     ```
     This will create a public key (`id_rsa.pub`) and a private key (`id_rsa`).

2. **Referencing the Key Pair:**
   - The `key_name` attribute in the `aws_instance` resource references the key pair created with the `aws_key_pair` resource.
   - This ensures that the EC2 instances are created with the specified key pair, allowing you to SSH into them using the corresponding private key.

### Key Points

- **Optional Attribute:** The `key_name` attribute is optional. If you don't specify it, the instance will be created without an SSH key, limiting direct SSH access.
- **Managed Key Pair:** By using the `aws_key_pair` resource, you can manage your key pairs directly in Terraform, ensuring they are created and referenced consistently.

By following this approach, you ensure that your EC2 instances are accessible via SSH using the key pair managed within your Terraform configuration.