#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/.env}"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/deployment_$(date +%Y%m%d_%H%M%S).log"

# Deployment steps control
SKIP_SERVER_SETUP=false
SKIP_DNS_UPDATE=false
SKIP_SITE_DEPLOY=false
SKIP_SSL_SETUP=false
DRY_RUN=false

# ================================================================================
# Logging Functions
# ================================================================================

log_info() {
    local msg="[INFO] $1"
    echo -e "${BLUE}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_success() {
    local msg="[SUCCESS] $1"
    echo -e "${GREEN}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_warning() {
    local msg="[WARNING] $1"
    echo -e "${YELLOW}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] $1"
    echo -e "${RED}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_step() {
    local msg="[STEP] $1"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$msg${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "$msg" >> "$LOG_FILE"
}

error_exit() {
    log_error "$1"
    log_error "Full deployment failed! Check log: $LOG_FILE"
    exit 1
}

# ================================================================================
# Initialization Functions
# ================================================================================

init_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    log_info "Deployment started at $(date)"
    log_info "Log file: $LOG_FILE"
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        log_success "Configuration loaded from $CONFIG_FILE"
    else
        log_warning "Config file not found: $CONFIG_FILE"
        log_warning "Using environment variables or defaults"
    fi
}

validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    local errors=0
    
    # Check if scripts exist
    local scripts=("setup-server.sh" "update_dns.sh" "deploy-site.sh")
    for script in "${scripts[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
            log_error "Required script not found: $script"
            errors=$((errors + 1))
        elif [[ ! -x "$SCRIPT_DIR/$script" ]]; then
            log_warning "Script not executable: $script, making it executable..."
            chmod +x "$SCRIPT_DIR/$script"
        fi
    done
    
    # Check required commands
    local commands=("curl" "dig" "nginx" "certbot")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_warning "Command not found: $cmd (will be installed during setup)"
        fi
    done
    
    # Check configuration if SSL is not skipped
    if [[ "$SKIP_SSL_SETUP" == "false" ]]; then
        if [[ -z "${DUCKDNS_DOMAIN:-}" ]]; then
            log_error "DUCKDNS_DOMAIN not set in config"
            errors=$((errors + 1))
        fi
        
        if [[ -z "${LETSENCRYPT_EMAIL:-}" ]]; then
            log_error "LETSENCRYPT_EMAIL not set in config"
            errors=$((errors + 1))
        fi
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo ""
        log_info "Please create $CONFIG_FILE with required values. See .env.example"
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# ================================================================================
# Deployment Step Functions
# ================================================================================

step_setup_server() {
    if [[ "$SKIP_SERVER_SETUP" == "true" ]]; then
        log_warning "Skipping server setup (--skip-server-setup)"
        return 0
    fi
    
    log_step "Step 1: Server Setup"
    log_info "Installing Nginx, Certbot, and configuring firewall..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: ./setup-server.sh"
        return 0
    fi
    
    "$SCRIPT_DIR/setup-server.sh" 2>&1 | tee -a "$LOG_FILE" || error_exit "Server setup failed"
    log_success "Server setup completed"
}

step_update_dns() {
    if [[ "$SKIP_DNS_UPDATE" == "true" ]]; then
        log_warning "Skipping DNS update (--skip-dns-update)"
        return 0
    fi
    
    log_step "Step 2: DNS Update"
    log_info "Updating DuckDNS records..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: ./update_dns.sh"
        return 0
    fi
    
    "$SCRIPT_DIR/update_dns.sh" 2>&1 | tee -a "$LOG_FILE" || error_exit "DNS update failed"
    log_success "DNS update completed"
}

step_deploy_site() {
    if [[ "$SKIP_SITE_DEPLOY" == "true" ]]; then
        log_warning "Skipping site deployment (--skip-site-deploy)"
        return 0
    fi
    
    log_step "Step 3: Site Deployment"
    log_info "Deploying website files..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: ./deploy-site.sh"
        return 0
    fi
    
    "$SCRIPT_DIR/deploy-site.sh" 2>&1 | tee -a "$LOG_FILE" || error_exit "Site deployment failed"
    log_success "Site deployment completed"
}

wait_for_dns_propagation() {
    local domain="${DUCKDNS_DOMAIN}.duckdns.org"
    local max_attempts=12
    local attempt=0
    
    log_info "Waiting for DNS propagation for $domain..."
    
    while [[ $attempt -lt $max_attempts ]]; do
        local resolved_ip
        resolved_ip=$(dig +short "$domain" @8.8.8.8 | tail -n1)
        
        if [[ -n "$resolved_ip" ]]; then
            log_success "DNS resolved: $domain → $resolved_ip"
            return 0
        fi
        
        attempt=$((attempt + 1))
        log_info "Attempt $attempt/$max_attempts - DNS not yet propagated, waiting 10 seconds..."
        sleep 10
    done
    
    log_warning "DNS not fully propagated after $((max_attempts * 10)) seconds"
    log_warning "Continuing with SSL setup anyway..."
}

step_setup_ssl() {
    if [[ "$SKIP_SSL_SETUP" == "true" ]]; then
        log_warning "Skipping SSL setup (--skip-ssl-setup)"
        return 0
    fi
    
    log_step "Step 4: SSL Certificate Setup"
    
    local domain="${DUCKDNS_DOMAIN}.duckdns.org"
    local email="${LETSENCRYPT_EMAIL}"
    
    log_info "Obtaining Let's Encrypt certificate for $domain..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: certbot --nginx -d $domain"
        return 0
    fi
    
    # Wait for DNS to propagate
    wait_for_dns_propagation
    
    # Check if certificate already exists
    if sudo certbot certificates 2>/dev/null | grep -q "$domain"; then
        log_warning "Certificate already exists for $domain"
        log_info "Attempting to renew certificate..."
        sudo certbot renew --nginx 2>&1 | tee -a "$LOG_FILE" || log_warning "Certificate renewal failed or not needed"
    else
        # Obtain new certificate
        sudo certbot --nginx \
            -d "$domain" \
            --non-interactive \
            --agree-tos \
            -m "$email" \
            --redirect 2>&1 | tee -a "$LOG_FILE" || error_exit "SSL certificate setup failed"
    fi
    
    log_success "SSL certificate setup completed"
    
    # Verify SSL
    verify_ssl "$domain"
}

verify_ssl() {
    local domain=$1
    
    log_info "Verifying SSL certificate..."
    
    if echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | grep -q "Verify return code: 0"; then
        log_success "SSL certificate is valid and trusted"
    else
        log_warning "SSL verification inconclusive. Manual check recommended:"
        echo "  openssl s_client -connect $domain:443 -servername $domain"
    fi
}

# ================================================================================
# Summary and Completion Functions
# ================================================================================

display_deployment_summary() {
    local duration=$1
    
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}              DEPLOYMENT SUMMARY${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    log_success "Full deployment completed successfully!"
    echo ""
    log_info "Deployment Details:"
    echo "  • Duration: ${duration}s"
    echo "  • Log file: $LOG_FILE"
    echo ""
    
    if [[ -n "${DUCKDNS_DOMAIN:-}" ]]; then
        local domain="${DUCKDNS_DOMAIN}.duckdns.org"
        log_info "Your Website:"
        echo "  • HTTP:  http://$domain"
        echo "  • HTTPS: https://$domain"
        echo ""
        log_info "Verification Commands:"
        echo "  • Test HTTP:  curl http://$domain"
        echo "  • Test HTTPS: curl https://$domain"
        echo "  • Check DNS:  dig $domain"
        echo "  • Check SSL:  openssl s_client -connect $domain:443"
    else
        local public_ip
        public_ip=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")
        log_info "Your Website:"
        echo "  • HTTP:  http://$public_ip"
    fi
    
    echo ""
    log_info "Next Steps:"
    echo "  • Test your website in a browser"
    echo "  • Set up automatic certificate renewal (certbot should do this automatically)"
    echo "  • Configure Nginx for your specific needs"
    echo "  • Monitor logs: tail -f /var/log/nginx/access.log"
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ================================================================================
# Help and Usage
# ================================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Full deployment script for static website with Nginx and SSL.

OPTIONS:
    --skip-server-setup     Skip server setup step
    --skip-dns-update       Skip DNS update step
    --skip-site-deploy      Skip site deployment step
    --skip-ssl-setup        Skip SSL certificate setup step
    --dry-run               Show what would be executed without running
    --help, -h              Show this help message

EXAMPLES:
    # Full deployment
    $0

    # Deploy without SSL (for testing)
    $0 --skip-ssl-setup

    # Update only DNS and deploy site
    $0 --skip-server-setup --skip-ssl-setup

    # Dry run to see what would happen
    $0 --dry-run

CONFIGURATION:
    Set configuration in $CONFIG_FILE (see .env.example)
    Required variables:
        - DUCKDNS_DOMAIN
        - DUCKDNS_TOKEN
        - LETSENCRYPT_EMAIL
        - SITE_SOURCE_DIR

EOF
}

# ================================================================================
# Main Function
# ================================================================================

main() {
    local start_time
    start_time=$(date +%s)
    
    # Initialize
    init_logging
    
    log_info "Starting full deployment pipeline..."
    
    # Load configuration
    load_config
    
    # Validate prerequisites
    validate_prerequisites
    
    # Execute deployment steps
    step_setup_server
    step_update_dns
    step_deploy_site
    step_setup_ssl
    
    # Calculate duration
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Display summary
    display_deployment_summary "$duration"
    
    log_info "Deployment finished at $(date)"
}

# ================================================================================
# Command Line Argument Parsing
# ================================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-server-setup)
                SKIP_SERVER_SETUP=true
                shift
                ;;
            --skip-dns-update)
                SKIP_DNS_UPDATE=true
                shift
                ;;
            --skip-site-deploy)
                SKIP_SITE_DEPLOY=true
                shift
                ;;
            --skip-ssl-setup)
                SKIP_SSL_SETUP=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                error_exit "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
}

# ================================================================================
# Script Entry Point
# ================================================================================

parse_arguments "$@"
main
