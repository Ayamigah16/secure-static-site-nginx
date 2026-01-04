#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ================================================================================
# Logging Functions
# ================================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

error_exit() {
    log_error "$1"
    exit 1
}

# ================================================================================
# Validation Functions
# ================================================================================

check_root() {
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root. Use sudo within the script."
    fi
}

is_package_installed() {
    dpkg -l | grep -q "^ii  $1"
}

# ================================================================================
# System Update Functions
# ================================================================================

update_system() {
    log_info "Updating package lists..."
    sudo apt update || error_exit "Failed to update package lists"

    log_info "Upgrading installed packages..."
    sudo apt upgrade -y || error_exit "Failed to upgrade packages"
    
    log_success "System packages updated"
}

# ================================================================================
# Package Installation Functions
# ================================================================================

install_nginx() {
    log_info "Checking Nginx installation..."
    
    if is_package_installed "nginx"; then
        log_warning "Nginx already installed"
        return 0
    fi
    
    log_info "Installing Nginx..."
    sudo apt install -y nginx || error_exit "Failed to install Nginx"
    
    # Verify installation
    nginx -v &>/dev/null || error_exit "Nginx installation verification failed"
    log_success "Nginx installed successfully"
}

install_certbot() {
    log_info "Checking Certbot installation..."
    
    if is_package_installed "certbot"; then
        log_warning "Certbot already installed"
        return 0
    fi
    
    log_info "Installing Certbot and dependencies..."
    sudo apt install -y certbot python3-certbot-nginx curl || error_exit "Failed to install Certbot"
    
    # Verify installation
    certbot --version &>/dev/null || error_exit "Certbot installation verification failed"
    log_success "Certbot installed successfully"
}

# ================================================================================
# Firewall Configuration Functions
# ================================================================================

configure_firewall() {
    log_info "Configuring UFW firewall..."
    
    # Check if UFW is installed
    if ! command -v ufw &> /dev/null; then
        log_warning "UFW not installed, skipping firewall configuration"
        return 0
    fi
    
    if ! sudo ufw status | grep -q "Status: active"; then
        log_info "Enabling UFW and setting up rules..."
        
        # Allow SSH (port 22)
        sudo ufw allow 22/tcp || error_exit "Failed to allow SSH port 22"
        
        # Allow HTTP (port 80)
        sudo ufw allow 80/tcp || error_exit "Failed to allow HTTP port 80"
        
        # Allow HTTPS (port 443)
        sudo ufw allow 443/tcp || error_exit "Failed to allow HTTPS port 443"
        
        # Enable firewall
        sudo ufw enable || error_exit "Failed to enable UFW"
        
        log_success "UFW firewall configured and enabled"
    else
        log_warning "UFW already active, updating rules..."
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        log_success "UFW rules updated"
    fi
    
    # Display UFW status
    log_info "Current UFW status:"
    sudo ufw status
}

# ================================================================================
# Nginx Service Management Functions
# ================================================================================

start_nginx_service() {
    log_info "Starting Nginx service..."
    
    if sudo systemctl is-active --quiet nginx; then
        log_warning "Nginx is already running"
    else
        sudo systemctl start nginx || error_exit "Failed to start Nginx"
        log_success "Nginx started"
    fi
}

enable_nginx_service() {
    log_info "Enabling Nginx at boot..."
    
    if sudo systemctl is-enabled --quiet nginx; then
        log_warning "Nginx already enabled at boot"
    else
        sudo systemctl enable nginx || error_exit "Failed to enable Nginx"
        log_success "Nginx enabled at boot"
    fi
}

verify_nginx() {
    log_info "Verifying Nginx status..."
    
    if sudo systemctl is-active --quiet nginx; then
        log_success "Nginx is running successfully"
        
        # Display Nginx status
        log_info "Nginx status:"
        sudo systemctl status nginx --no-pager -l | head -n 10
        return 0
    else
        error_exit "Nginx is not running"
    fi
}

# ================================================================================
# Display Functions
# ================================================================================

display_completion_info() {
    local public_ip
    public_ip=$(curl -s https://api.ipify.org)
    
    echo ""
    log_success "Server setup complete!"
    echo ""
    log_info "Summary:"
    echo "  • Nginx installed and running"
    echo "  • Certbot installed"
    echo "  • UFW firewall configured"
    echo "  • Server IP: $public_ip"
    echo ""
    log_info "You can verify Nginx is working by visiting: http://$public_ip"
    echo ""
}

# ================================================================================
# Main Function
# ================================================================================

main() {
    log_info "Starting server setup..."
    
    # Pre-flight checks
    check_root
    
    # System updates
    update_system
    
    # Install packages
    install_nginx
    install_certbot
    
    # Configure firewall
    configure_firewall
    
    # Setup Nginx service
    enable_nginx_service
    start_nginx_service
    
    # Verify installation
    verify_nginx
    
    # Display completion info
    display_completion_info
}

# ================================================================================
# Script Entry Point
# ================================================================================

main "$@"
