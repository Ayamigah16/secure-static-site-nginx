#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file location
CONFIG_FILE="${CONFIG_FILE:-$(dirname "$0")/.env}"

# ================================================================================
# Logging Functions
# ================================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

error_exit() {
    log_error "$1"
    exit 1
}

# ================================================================================
# Configuration Functions
# ================================================================================

load_config() {
    log_info "Loading configuration..."
    
    if [[ -f "$CONFIG_FILE" ]]; then
        # Source the config file
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        log_success "Configuration loaded from $CONFIG_FILE"
    else
        log_warning "Config file not found at: $CONFIG_FILE"
        log_info "Using environment variables or defaults"
    fi
    
    # Set defaults if not provided
    DOMAIN="${DUCKDNS_DOMAIN:-${DOMAIN:-}}"
    TOKEN="${DUCKDNS_TOKEN:-${TOKEN:-}}"
    
    validate_config
}

validate_config() {
    local errors=0
    
    if [[ -z "$DOMAIN" ]]; then
        log_error "DOMAIN or DUCKDNS_DOMAIN not set"
        errors=$((errors + 1))
    fi
    
    if [[ -z "$TOKEN" ]]; then
        log_error "TOKEN or DUCKDNS_TOKEN not set"
        errors=$((errors + 1))
    fi
    
    if [[ "$TOKEN" == "YOUR_DUCKDNS_TOKEN" ]]; then
        log_error "TOKEN is still set to placeholder value"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo ""
        log_info "Please set configuration in one of these ways:"
        echo "  1. Create $CONFIG_FILE with:"
        echo "     DUCKDNS_DOMAIN=\"your-domain\""
        echo "     DUCKDNS_TOKEN=\"your-token\""
        echo ""
        echo "  2. Set environment variables:"
        echo "     export DUCKDNS_DOMAIN=\"your-domain\""
        echo "     export DUCKDNS_TOKEN=\"your-token\""
        echo ""
        exit 1
    fi
}

# ================================================================================
# Network Functions
# ================================================================================

get_public_ip() {
    local ip
    local services=(
        "https://api.ipify.org"
        "https://icanhazip.com"
        "https://ifconfig.me"
    )
    
    log_info "Fetching public IP address..."
    
    for service in "${services[@]}"; do
        ip=$(curl -s --max-time 5 "$service" 2>/dev/null | tr -d '[:space:]')
        
        if validate_ip "$ip"; then
            log_success "Public IP: $ip"
            echo "$ip"
            return 0
        fi
    done
    
    error_exit "Failed to retrieve valid public IP address"
}

validate_ip() {
    local ip=$1
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ $ip =~ $regex ]]; then
        # Check each octet is <= 255
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if [[ $octet -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# ================================================================================
# DuckDNS Functions
# ================================================================================

update_duckdns() {
    local domain=$1
    local token=$2
    local ip=$3
    local response=""
    local curl_exit_code=0
    
    # Validate parameters
    if [[ -z "$domain" ]]; then
        error_exit "Domain parameter is empty"
    fi
    if [[ -z "$token" ]]; then
        error_exit "Token parameter is empty"
    fi
    if [[ -z "$ip" ]]; then
        error_exit "IP parameter is empty"
    fi
    
    # Debug: Show what we're sending (mask token for security)
    log_info "Updating DuckDNS record: ${domain}.duckdns.org → $ip"
    log_info "Domain length: ${#domain}, Token length: ${#token}, IP: $ip"
    log_info "URL: https://www.duckdns.org/update?domains=$domain&token=${token:0:10}...&ip=$ip"
    
    # Attempt curl with error handling
    response=$(curl -s -w '\n%{http_code}' "https://www.duckdns.org/update?domains=$domain&token=$token&ip=$ip" 2>&1) || curl_exit_code=$?
    
    # Check if curl command failed
    if [[ $curl_exit_code -ne 0 ]]; then
        log_error "Curl command failed with exit code: $curl_exit_code"
        case $curl_exit_code in
            3) log_error "Exit code 3: URL malformed - check domain, token, or IP contains invalid characters" ;;
            6) log_error "Exit code 6: Could not resolve host" ;;
            7) log_error "Exit code 7: Failed to connect to host" ;;
            28) log_error "Exit code 28: Operation timeout" ;;
            *) log_error "Unknown curl error" ;;
        esac
        error_exit "Failed to connect to DuckDNS API"
    fi
    
    # Extract HTTP status code and response body
    local http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    log_info "HTTP Status: $http_code"
    log_info "Response: $response"
    
    if [[ "$response" == "OK" ]]; then
        log_success "DuckDNS updated successfully"
        return 0
    elif [[ "$response" == "KO" ]]; then
        log_error "DuckDNS API returned 'KO' - Invalid domain or token"
        log_error "Domain: $domain"
        log_error "Token: ${token:0:10}... (first 10 chars)"
        log_error "IP: $ip"
        log_error ""
        log_error "Please verify:"
        log_error "1. Your DuckDNS domain is correct (without .duckdns.org)"
        log_error "2. Your DuckDNS token is valid (get it from https://www.duckdns.org/)"
        log_error "3. Check your .env file or GitHub secrets"
        error_exit "DuckDNS update failed"
    else
        log_error "Unexpected response from DuckDNS: $response"
        error_exit "DuckDNS update failed with unexpected response"
    fi
}

verify_dns_update() {
    local domain=$1
    local expected_ip=$2
    
    log_info "Verifying DNS propagation (this may take a few moments)..."
    
    # Wait a bit for DNS to update
    sleep 2
    
    local resolved_ip
    resolved_ip=$(dig +short "${domain}.duckdns.org" @8.8.8.8 | tail -n1)
    
    if [[ "$resolved_ip" == "$expected_ip" ]]; then
        log_success "DNS verification successful: ${domain}.duckdns.org resolves to $resolved_ip"
        return 0
    else
        log_warning "DNS not yet propagated. Expected: $expected_ip, Got: $resolved_ip"
        log_info "DNS propagation may take a few minutes. Try: dig ${domain}.duckdns.org"
        return 1
    fi
}

# ================================================================================
# Display Functions
# ================================================================================

display_summary() {
    local domain=$1
    local ip=$2
    
    echo ""
    log_success "DNS update complete!"
    echo ""
    log_info "Summary:"
    echo "  • Domain: ${domain}.duckdns.org"
    echo "  • IP Address: $ip"
    echo "  • Status: Updated"
    echo ""
    log_info "Test your domain:"
    echo "  • dig ${domain}.duckdns.org"
    echo "  • nslookup ${domain}.duckdns.org"
    echo "  • curl http://${domain}.duckdns.org"
    echo ""
}

# ================================================================================
# Main Function
# ================================================================================

main() {
    log_info "Starting DuckDNS update..."
    
    # Load and validate configuration
    load_config
    
    # Get public IP
    local public_ip
    public_ip=$(get_public_ip)
    
    # Update DuckDNS
    update_duckdns "$DOMAIN" "$TOKEN" "$public_ip"
    
    # Verify DNS update (optional, won't fail if not immediate)
    verify_dns_update "$DOMAIN" "$public_ip" || true
    
    # Display summary
    display_summary "$DOMAIN" "$public_ip"
}

# ================================================================================
# Script Entry Point
# ================================================================================

main "$@"
