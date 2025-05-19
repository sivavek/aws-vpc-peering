# [aws-vpc-peering] **Terraform Infrastructure Deployment Project**

<img width="1244" alt="image" src="[https://github.com/user-attachments/assets/05d962f8-77e6-40f1-b9e5-b228ef47c052](https://github.com/sivavek/aws-vpc-peering/blob/main/images/complete%20arch%20diag.png)" />

## **Overview**
This project contains Terraform scripts to provision and manage cloud infrastructure in an automated, version-controlled way. The infrastructure includes compute resources with SSH access configured for secure management.

## **Prerequisites**

Terraform (v1.0.0+)
Cloud provider CLI tools (AWS CLI, Azure CLI, or GCP CLI)
SSH key pair for secure access
Git for version control

## **Architecture**
The deployment creates the following resources: [ref above screenshot]

- Virtual Private Cloud (VPC) - 2 VPCs in us-east-1 and 1 in us-west-1, with proper networking 
    - i.e. peering connections between VPC for bilateral communication
- Compute instances with SSH access
- Security groups to manage access
- Supporting resources for monitoring and management (enable flow logs and store in S3 bucket)


# [Follow steps below if you'd like to try this project]

## Getting Started
### 1. Clone the Repository
bashgit clone https://github.com/yourusername/your-terraform-project.git
cd your-terraform-project

### 2. Generate SSH Key Pair
If you don't already have an SSH key pair:
bashssh-keygen -t rsa -b 2048 -f ~/.ssh/terraform_key
This will create:

~/.ssh/terraform_key (private key)
~/.ssh/terraform_key.pub (public key)

Set proper permissions for your private key:
bashchmod 400 ~/.ssh/terraform_key

### 3. Update Configuration
Edit the variables.tf file to set your preferences, or create a terraform.tfvars file:
hcl# terraform.tfvars
region = "us-west-2"
instance_type = "t2.micro"
ssh_public_key_path = "~/.ssh/terraform_key.pub"

### 4. Initialize Terraform
terraform init

### 5. Preview Changes
terraform plan

### 6. Apply Configuration
terraform apply

Confirm by typing yes when prompted.

### 7. Access Resources
After deployment completes, Terraform will output information about the created resources, including IP addresses. Connect using:
ssh -i ~/.ssh/terraform_key username@instance_ip

## Managing the Infrastructure
### Updating Resources
After making changes to the Terraform files:
terraform plan  # Preview changes
terraform apply  # Apply changes

### Destroying Resources
To tear down all provisioned infrastructure:
terraform destroy

### Project Structure
        .
        ├── main.tf           # Main Terraform configuration
        ├── variables.tf      # Variable declarations
        ├── outputs.tf        # Output configurations
        ├── terraform.tfvars  # Variable values (git-ignored)
        ├── modules/          # Reusable modules
        │   ├── networking/
        │   └── compute/
        ├── images/           # Documentation images
        │   └── architecture.svg
        └── README.md         # This file

### Security Considerations

Private keys should never be committed to git
Use a .gitignore file to prevent accidental commits of sensitive files
Consider using a secret management solution for production environments
Restrict security group rules to only necessary ports and source IPs

## Troubleshooting

### Common Issues

### _SSH Connection Problems_

- Verify that your security groups allow SSH access
- Ensure proper permissions on your private key file (chmod 400)
- Confirm you're using the correct username for the OS


### _Terraform State Corruption_

- Consider using remote state with locking for team environments
- Backup your terraform.tfstate file regularly


### _Resource Creation Failures_

- Check cloud provider quotas and limits
- Review cloud provider console for detailed error messages
