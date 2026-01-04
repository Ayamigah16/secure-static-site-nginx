#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_FILE="${CONFIG_FILE:-$(dirname "$0")/.env}"
DEFAULT_SOURCE_DIR="$HOME/site"
DEFAULT_WEB_ROOT="/var/www/html"
BACKUP_DIR="/var/backups/nginx-sites"
MAX_BACKUPS=5

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
# Configuration Functions
# ================================================================================

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        log_info "Configuration loaded from $CONFIG_FILE"
    fi
    
    # Set variables with defaults
    SOURCE_DIR="${SITE_SOURCE_DIR:-${LOCAL_REPO_DIR:-$DEFAULT_SOURCE_DIR}}"
    WEB_ROOT="${WEB_ROOT:-$DEFAULT_WEB_ROOT}"
}

validate_config() {
    log_info "Validating configuration..."
    
    # Check if source directory exists
    if [[ ! -d "$SOURCE_DIR" ]]; then
        error_exit "Source directory does not exist: $SOURCE_DIR"
    fi
    
    # Check if source directory has content
    if [[ -z "$(ls -A "$SOURCE_DIR" 2>/dev/null)" ]]; then
        error_exit "Source directory is empty: $SOURCE_DIR"
    fi
    
    # Check if web root exists
    if [[ ! -d "$WEB_ROOT" ]]; then
        log_warning "Web root does not exist: $WEB_ROOT"
        log_info "Creating web root directory..."
        sudo mkdir -p "$WEB_ROOT" || error_exit "Failed to create web root"
    fi
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root. Consider running as regular user with sudo."
    fi
    
    log_success "Configuration validated"
}

# ================================================================================
# Backup Functions
# ================================================================================

create_backup() {
    log_info "Creating backup of current deployment..."
    
    # Create backup directory if it doesn't exist
    sudo mkdir -p "$BACKUP_DIR" || error_exit "Failed to create backup directory"
    
    # Check if web root has content to backup
    if [[ -z "$(ls -A "$WEB_ROOT" 2>/dev/null)" ]]; then
        log_warning "Web root is empty, skipping backup"
        return 0
    fi
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/backup_${timestamp}.tar.gz"
    
    # Create compressed backup
    sudo tar -czf "$backup_file" -C "$WEB_ROOT" . 2>/dev/null || {
        log_warning "Backup creation failed, continuing anyway..."
        return 0
    }
    
    log_success "Backup created: $backup_file"
    
    # Cleanup old backups
    cleanup_old_backups
}

cleanup_old_backups() {
    local backup_count
    backup_count=$(sudo find "$BACKUP_DIR" -name "backup_*.tar.gz" -type f 2>/dev/null | wc -l)
    
    if [[ $backup_count -gt $MAX_BACKUPS ]]; then
        log_info "Cleaning up old backups (keeping last $MAX_BACKUPS)..."
        sudo find "$BACKUP_DIR" -name "backup_*.tar.gz" -type f -printf '%T+ %p\n' | \
            sort -r | \
            tail -n +$((MAX_BACKUPS + 1)) | \
            cut -d' ' -f2- | \
            xargs -r sudo rm -f
        log_success "Old backups cleaned up"
    fi
}

rollback_deployment() {
    log_warning "Rolling back to previous deployment..."
    
    local latest_backup
    latest_backup=$(sudo find "$BACKUP_DIR" -name "backup_*.tar.gz" -type f -printf '%T+ %p\n' 2>/dev/null | sort -r | head -n1 | cut -d' ' -f2-)
    
    if [[ -z "$latest_backup" ]]; then
        error_exit "No backup found for rollback"
    fi
    
    log_info "Restoring from: $latest_backup"
    
    # Clear web root
    sudo rm -rf "${WEB_ROOT:?}"/*
    
    # Extract backup
    sudo tar -xzf "$latest_backup" -C "$WEB_ROOT" || error_exit "Failed to restore backup"
    
    # Set permissions
    sudo chown -R www-data:www-data "$WEB_ROOT"
    sudo find "$WEB_ROOT" -type f -exec chmod 644 {} \;
    sudo find "$WEB_ROOT" -type d -exec chmod 755 {} \;
    
    log_success "Rollback completed"
}

# ================================================================================
# Deployment Functions
# ================================================================================

show_deployment_preview() {
    log_info "Deployment preview:"
    echo "  • Source: $SOURCE_DIR"
    echo "  • Destination: $WEB_ROOT"
    echo ""
    
    log_info "Files to be deployed:"
    find "$SOURCE_DIR" -type f | sed "s|$SOURCE_DIR/|  • |" | head -n 20
    
    local total_files
    total_files=$(find "$SOURCE_DIR" -type f | wc -l)
    
    if [[ $total_files -gt 20 ]]; then
        echo "  ... and $((total_files - 20)) more files"
    fi
    echo ""
}

deploy_files() {
    log_info "Deploying files..."
    
    # Use rsync for efficient deployment
    sudo rsync -avz --delete \
        --exclude='.git' \
        --exclude='.env' \
        --exclude='*.log' \
        --exclude='node_modules' \
        "$SOURCE_DIR/" "$WEB_ROOT/" || error_exit "File deployment failed"
    
    log_success "Files deployed successfully"
}

set_permissions() {
    log_info "Setting correct permissions..."
    
    # Set ownership to www-data
    sudo chown -R www-data:www-data "$WEB_ROOT" || error_exit "Failed to set ownership"
    
    # Set file permissions (644 for files, 755 for directories)
    sudo find "$WEB_ROOT" -type f -exec chmod 644 {} \; || error_exit "Failed to set file permissions"
    sudo find "$WEB_ROOT" -type d -exec chmod 755 {} \; || error_exit "Failed to set directory permissions"
    
    log_success "Permissions set correctly"
}

validate_nginx_config() {
    log_info "Validating Nginx configuration..."
    
    if sudo nginx -t 2>&1 | grep -q "syntax is ok"; then
        log_success "Nginx configuration is valid"
        return 0
    else
        log_error "Nginx configuration validation failed:"
        sudo nginx -t
        return 1
    fi
}

reload_nginx() {
    log_info "Reloading Nginx..."
    
    if ! validate_nginx_config; then
        error_exit "Cannot reload Nginx due to configuration errors"
    fi
    
    sudo systemctl reload nginx || error_exit "Failed to reload Nginx"
    
    log_success "Nginx reloaded successfully"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check if index file exists
    local index_files=("index.html" "index.htm" "index.php")
    local found_index=false
    
    for index_file in "${index_files[@]}"; do
        if [[ -f "$WEB_ROOT/$index_file" ]]; then
            found_index=true
            log_success "Found index file: $index_file"
            break
        fi
    done
    
    if [[ "$found_index" == "false" ]]; then
        log_warning "No index file found in web root"
    fi
    
    # Check if Nginx is running
    if sudo systemctl is-active --quiet nginx; then
        log_success "Nginx is running"
    else
        error_exit "Nginx is not running"
    fi
}

# ================================================================================
# Display Functions
# ================================================================================

display_deployment_summary() {
    local file_count
    file_count=$(find "$WEB_ROOT" -type f | wc -l)
    
    echo ""
    log_success "Deployment complete!"
    echo ""
    log_info "Summary:"
    echo "  • Files deployed: $file_count"
    echo "  • Web root: $WEB_ROOT"
    echo "  • Nginx status: Running"
    echo "  • Backup location: $BACKUP_DIR"
    echo ""
    log_info "Test your deployment:"
    
    # Try to get server IP
    local server_ip
    server_ip=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")
    echo "  • curl http://$server_ip"
    echo "  • Or visit http://$server_ip in your browser"
    echo ""
    
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        if [[ -n "${DUCKDNS_DOMAIN:-}" ]]; then
            echo "  • curl http://${DUCKDNS_DOMAIN}.duckdns.org"
            echo ""
        fi
    fi
}

# ================================================================================
# Main Function
# ================================================================================

main() {
    log_info "Starting site deployment..."
    
    # Load configuration
    load_config
    validate_config
    
    # Show what will be deployed
    show_deployment_preview
    
    # Create backup before deployment
    create_backup
    
    # Deploy files
    deploy_files
    
    # Set correct permissions
    set_permissions
    
    # Reload Nginx
    reload_nginx
    
    # Verify deployment
    verify_deployment
    
    # Display summary
    display_deployment_summary
}

# ================================================================================
# Script Entry Point
# ================================================================================

# Check for command-line options
case "${1:-}" in
    --rollback)
        log_info "Rollback requested"
        load_config
        rollback_deployment
        reload_nginx
        log_success "Rollback complete"
        exit 0
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --rollback    Rollback to previous deployment"
        echo "  --help, -h    Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  SITE_SOURCE_DIR   Source directory (default: $DEFAULT_SOURCE_DIR)"
        echo "  WEB_ROOT          Web root directory (default: $DEFAULT_WEB_ROOT)"
        echo "  CONFIG_FILE       Config file path (default: .env)"
        echo ""
        exit 0
        ;;
    "")
        main "$@"
        ;;
    *)
        error_exit "Unknown option: $1. Use --help for usage information."
        ;;
esac
