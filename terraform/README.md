# Terraform Infrastructure Setup

This directory contains Terraform configuration to provision an EC2 instance for hosting your static website with Nginx.

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** installed (>= 1.0)
   ```bash
   # Install Terraform
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```

3. **AWS CLI** configured with credentials
   ```bash
   aws configure
   # Enter: AWS Access Key ID, Secret Access Key, Region, Output format
   ```

4. **SSH Key Pair** generated
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
   ```

## 🚀 Quick Start

### 1. Configure Variables

Copy the example variables file:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings:
```hcl
aws_region          = "us-east-1"
project_name        = "my-static-site"
instance_type       = "t3.micro"
ssh_allowed_cidr    = ["YOUR_IP/32"]  # Restrict SSH to your IP
use_elastic_ip      = true
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

This shows what resources will be created:
- EC2 instance (Ubuntu 24.04 LTS)
- Security Group (ports 22, 80, 443)
- SSH Key Pair
- Elastic IP (optional)

### 4. Apply Configuration

```bash
terraform apply
```

Type `yes` to confirm and create resources.

### 5. Get Outputs

```bash
terraform output
```

Example output:
```
instance_id              = "i-0123456789abcdef"
instance_public_ip       = "54.123.45.67"
ssh_connection_string    = "ssh -i ~/.ssh/secure-static-site-deployer-key ubuntu@54.123.45.67"
elastic_ip              = "54.123.45.67"
```

## 📁 Files Overview

- **main.tf** - Main infrastructure resources (EC2, security group, key pair)
- **variables.tf** - Input variable definitions
- **outputs.tf** - Output values after apply
- **user-data.sh** - EC2 initialization script
- **terraform.tfvars** - Your variable values (gitignored)
- **terraform.tfvars.example** - Example configuration

## 🔧 Configuration Options

### Instance Types

| Type | vCPU | RAM | Cost/Month | Use Case |
|------|------|-----|------------|----------|
| t3.micro | 2 | 1 GB | ~$7.50 | Small sites, testing |
| t3.small | 2 | 2 GB | ~$15 | Medium traffic |
| t3.medium | 2 | 4 GB | ~$30 | High traffic |

### Security Best Practices

1. **Restrict SSH Access**
   ```hcl
   ssh_allowed_cidr = ["YOUR_IP/32"]  # Only your IP
   ```

2. **Use Elastic IP** for consistent DNS
   ```hcl
   use_elastic_ip = true
   ```

3. **Enable Encryption**
   - Root volume encryption: ✅ Enabled by default
   - EBS volumes: ✅ Encrypted

## 🔄 Workflow Integration

### Update GitHub Actions Secrets

After `terraform apply`, update your GitHub repository secrets:

```bash
# Get the values
terraform output instance_public_ip
terraform output ssh_connection_string

# Add to GitHub: Settings → Secrets → Actions
SSH_HOST     = <instance_public_ip>
SSH_USER     = ubuntu
SSH_PRIVATE_KEY = <contents of ~/.ssh/id_rsa>
```

### Connect to Instance

```bash
# Use the output connection string
$(terraform output -raw ssh_connection_string)

# Or manually
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw instance_public_ip)
```

### Run Initial Setup

Once connected, run your setup script:
```bash
cd /home/ubuntu/secure-static-site-nginx
./setup-server.sh
```

## 🛠️ Common Commands

```bash
# View current state
terraform show

# List resources
terraform state list

# Get specific output
terraform output instance_public_ip

# Refresh state
terraform refresh

# Format configuration
terraform fmt

# Validate configuration
terraform validate

# Create execution plan and save
terraform plan -out=tfplan

# Apply saved plan
terraform apply tfplan
```

## 🗑️ Destroy Resources

To remove all infrastructure:

```bash
terraform destroy
```

⚠️ **Warning**: This will permanently delete:
- EC2 instance
- Elastic IP
- Security group
- SSH key pair

## 🔍 Troubleshooting

### Issue: "Error launching source instance: VPCIdNotSpecified"

**Solution**: Specify VPC and subnet in `terraform.tfvars`:
```hcl
vpc_id    = "vpc-xxxxxxxx"
subnet_id = "subnet-xxxxxxxx"
```

Or use default VPC:
```bash
# Find default VPC
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true"

# Find default subnet
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxxxxx"
```

### Issue: "InvalidKeyPair.NotFound"

**Solution**: Check SSH key exists:
```bash
ls -la ~/.ssh/id_rsa.pub
```

### Issue: "Resource already exists"

**Solution**: Import existing resource:
```bash
terraform import aws_instance.web_server i-xxxxxxxxx
```

### Issue: "Insufficient permissions"

**Solution**: Ensure AWS user has these permissions:
- EC2: Full access
- VPC: Read/Write
- IAM: CreateKeyPair

## 📊 Cost Estimation

Free Tier (12 months):
- t3.micro: 750 hours/month FREE
- EBS: 30 GB FREE
- Data transfer: 15 GB/month FREE

After Free Tier:
- t3.micro: ~$7.50/month
- Elastic IP: $3.60/month (if not attached to running instance)
- EBS (20 GB): ~$2/month

**Total**: ~$13/month for a small static site

## 🔐 Security Features

- ✅ Encrypted root volume (EBS)
- ✅ Security group (least privilege)
- ✅ SSH key authentication (no passwords)
- ✅ Automatic security updates
- ✅ Sudo without password for deploy user
- ✅ UFW firewall (configured by setup-server.sh)

## 📚 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 🎯 Next Steps

After provisioning:

1. ✅ Update GitHub Actions secrets with new IP
2. ✅ Run `setup-server.sh` on the instance
3. ✅ Update DNS records with Elastic IP
4. ✅ Trigger GitHub Actions deployment
5. ✅ Verify site is accessible
