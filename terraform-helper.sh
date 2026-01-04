#!/bin/bash
set -euo pipefail

# ================================================================================
# Terraform Helper Script
# ================================================================================
# This script helps you provision and manage AWS EC2 infrastructure with Terraform
# Usage: ./terraform-helper.sh [command]
# Commands: init, plan, apply, destroy, output, connect

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

error_exit() {
    log_error "$1"
    exit 1
}

# Check if Terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        echo ""
        echo "Install Terraform:"
        echo "  Ubuntu/Debian:"
        echo "    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg"
        echo "    echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list"
        echo "    sudo apt update && sudo apt install terraform"
        exit 1
    fi
}

# Check if AWS CLI is configured
check_aws() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        echo ""
        echo "Install AWS CLI:"
        echo "  curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\""
        echo "  unzip awscliv2.zip"
        echo "  sudo ./aws/install"
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured"
        echo ""
        echo "Configure AWS CLI:"
        echo "  aws configure"
        exit 1
    fi
}

# Navigate to terraform directory
cd "$(dirname "$0")/terraform"

# Main command handling
case "${1:-help}" in
    init)
        log_info "Initializing Terraform..."
        check_terraform
        check_aws
        
        if [[ ! -f "terraform.tfvars" ]]; then
            log_info "Creating terraform.tfvars from example..."
            cp terraform.tfvars.example terraform.tfvars
            log_success "Created terraform.tfvars - please edit it with your settings"
            exit 0
        fi
        
        terraform init
        log_success "Terraform initialized"
        ;;
    
    plan)
        log_info "Creating Terraform execution plan..."
        check_terraform
        check_aws
        terraform plan
        ;;
    
    apply)
        log_info "Applying Terraform configuration..."
        check_terraform
        check_aws
        terraform apply
        
        if [[ $? -eq 0 ]]; then
            log_success "Infrastructure provisioned successfully!"
            echo ""
            log_info "Next steps:"
            echo "  1. Update GitHub Actions secrets:"
            echo "     SSH_HOST=$(terraform output -raw instance_public_ip)"
            echo "     SSH_USER=ubuntu"
            echo "     SSH_PRIVATE_KEY=<contents of ~/.ssh/id_rsa>"
            echo ""
            echo "  2. Connect to instance:"
            echo "     $(terraform output -raw ssh_connection_string)"
            echo ""
            echo "  3. Run setup script:"
            echo "     cd /home/ubuntu/secure-static-site-nginx"
            echo "     ./setup-server.sh"
        fi
        ;;
    
    destroy)
        log_info "Destroying Terraform-managed infrastructure..."
        check_terraform
        
        echo -e "${YELLOW}WARNING: This will destroy all resources!${NC}"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        
        if [[ "$confirm" == "yes" ]]; then
            terraform destroy
            log_success "Infrastructure destroyed"
        else
            log_info "Destroy cancelled"
        fi
        ;;
    
    output)
        log_info "Terraform outputs:"
        terraform output
        ;;
    
    connect)
        log_info "Connecting to EC2 instance..."
        ssh_command=$(terraform output -raw ssh_connection_string 2>/dev/null)
        
        if [[ -z "$ssh_command" ]]; then
            error_exit "No instance found. Run 'terraform apply' first"
        fi
        
        log_info "Running: $ssh_command"
        eval "$ssh_command"
        ;;
    
    validate)
        log_info "Validating Terraform configuration..."
        terraform fmt -check
        terraform validate
        log_success "Configuration is valid"
        ;;
    
    fmt)
        log_info "Formatting Terraform files..."
        terraform fmt -recursive
        log_success "Files formatted"
        ;;
    
    help|*)
        echo "Terraform Helper Script"
        echo ""
        echo "Usage: ./terraform-helper.sh [command]"
        echo ""
        echo "Commands:"
        echo "  init      - Initialize Terraform and create tfvars file"
        echo "  plan      - Show execution plan"
        echo "  apply     - Create infrastructure"
        echo "  destroy   - Destroy all infrastructure"
        echo "  output    - Show output values"
        echo "  connect   - SSH into the EC2 instance"
        echo "  validate  - Validate configuration"
        echo "  fmt       - Format Terraform files"
        echo "  help      - Show this help message"
        echo ""
        echo "Quick Start:"
        echo "  1. ./terraform-helper.sh init"
        echo "  2. Edit terraform/terraform.tfvars"
        echo "  3. ./terraform-helper.sh plan"
        echo "  4. ./terraform-helper.sh apply"
        echo "  5. ./terraform-helper.sh connect"
        ;;
esac
