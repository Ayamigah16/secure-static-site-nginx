# Secure Static Site with Nginx

Production-ready deployment automation scripts for hosting a static website with Nginx, automatic DNS configuration, and Let's Encrypt SSL certificates.

---

## 🚀 Features

- **Automated Server Setup** - Install and configure Nginx with one command
- **DNS Management** - Automatic DuckDNS updates with validation
- **Site Deployment** - Rsync-based deployment with backup and rollback
- **SSL/TLS Automation** - Let's Encrypt certificate management
- **Full Orchestration** - Complete deployment pipeline with selective execution
- **Production-Ready** - Error handling, logging, validation, and safety checks

---

## 📋 Prerequisites

- **Option A: Manual Setup**
  - Ubuntu 20.04 LTS or newer server
  - SSH access to your server
  
- **Option B: Terraform (Recommended)**
  - AWS account with EC2 access
  - Terraform installed (>= 1.0)
  - AWS CLI configured
  
- **For Both**:
  - Domain name (or free DuckDNS account)
  - Basic knowledge of Linux commands

---

## 🏗️ Infrastructure Setup

### Option A: Terraform (Recommended)

Automated EC2 instance provisioning with Infrastructure as Code:

```bash
# Initialize Terraform
./terraform-helper.sh init

# Edit configuration
nano terraform/terraform.tfvars

# Review plan
./terraform-helper.sh plan

# Create infrastructure
./terraform-helper.sh apply

# Connect to instance
./terraform-helper.sh connect
```

See [terraform/README.md](terraform/README.md) for detailed documentation.

**Benefits:**
- ✅ Reproducible infrastructure
- ✅ Automated security group configuration
- ✅ Elastic IP for persistent address
- ✅ Version controlled infrastructure
- ✅ Easy to destroy and recreate

### Option B: Manual Server Setup

If you already have a server or prefer manual setup, skip to [Quick Start](#-quick-start).

---

## 🛠️ Quick Start

### 1. Initial Setup

Clone this repository and configure your environment:

```bash
# Copy the example configuration
cp .env.example .env

# Edit .env with your values
nano .env
```

Required configuration in `.env`:
```bash
DUCKDNS_DOMAIN="your-domain"        # Without .duckdns.org
DUCKDNS_TOKEN="your-token"          # From https://www.duckdns.org/
LETSENCRYPT_EMAIL="you@email.com"   # For SSL certificates
SITE_SOURCE_DIR="$HOME/site"        # Your website files location
```

### 2. Prepare Your Website

Create your website files in the source directory:

```bash
mkdir -p $HOME/site
cat > $HOME/site/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>My Website</title>
</head>
<body>
    <h1>Welcome to My Website</h1>
    <p>This site is running on Nginx with SSL!</p>
</body>
</html>
EOF
```

### 3. Run Full Deployment

Execute the complete deployment pipeline:

```bash
./full_deploy.sh
```

That's it! Your website will be live with HTTPS.

---

## 📚 Scripts Overview

### 1. **setup-server.sh**
Installs and configures the server environment.

**What it does:**
- Updates system packages
- Installs Nginx and Certbot
- Configures UFW firewall
- Starts and enables Nginx service
- Validates all installations

**Usage:**
```bash
./setup-server.sh
```

**Features:**
- ✅ Idempotent (safe to run multiple times)
- ✅ Colored output for easy reading
- ✅ Installation validation
- ✅ Service status verification

---

### 2. **update_dns.sh**
Updates DuckDNS with your server's public IP address.

**What it does:**
- Retrieves public IP from multiple services
- Validates IP address format
- Updates DuckDNS A record
- Verifies DNS propagation
- Confirms update with dig

**Usage:**
```bash
./update_dns.sh
```

**Configuration:**
- Reads from `.env` file or environment variables
- Falls back to multiple IP services if one fails
- Validates DuckDNS API response

**Features:**
- ✅ Secure credential management
- ✅ IP validation
- ✅ DNS verification
- ✅ Multiple fallback services

---

### 3. **deploy-site.sh**
Deploys your website files with backup and rollback capabilities.

**What it does:**
- Validates source directory
- Creates compressed backup
- Deploys files with rsync
- Sets proper permissions
- Validates Nginx configuration
- Reloads Nginx safely

**Usage:**
```bash
# Normal deployment
./deploy-site.sh

# Rollback to previous version
./deploy-site.sh --rollback

# Show help
./deploy-site.sh --help
```

**Features:**
- ✅ Automatic backups before deployment
- ✅ Rollback capability
- ✅ Backup rotation (keeps last 5)
- ✅ Nginx config validation
- ✅ Smart rsync (excludes .git, .env, node_modules)
- ✅ Deployment preview

**Backup Location:** `/var/backups/nginx-sites/`

---

### 4. **full_deploy.sh**
Complete deployment orchestration for the entire stack.

**What it does:**
1. Sets up server (Nginx, Certbot, firewall)
2. Updates DNS records
3. Deploys website files
4. Obtains/renews SSL certificate
5. Verifies everything is working

**Usage:**
```bash
# Full deployment
./full_deploy.sh

# Skip specific steps
./full_deploy.sh --skip-server-setup
./full_deploy.sh --skip-dns-update
./full_deploy.sh --skip-site-deploy
./full_deploy.sh --skip-ssl-setup

# Dry run (preview without executing)
./full_deploy.sh --dry-run

# Show help
./full_deploy.sh --help
```

**Features:**
- ✅ Selective step execution
- ✅ Comprehensive logging
- ✅ Dry run mode
- ✅ DNS propagation wait
- ✅ Certificate management (new/renewal)
- ✅ SSL verification
- ✅ Duration tracking
- ✅ Beautiful deployment summary

**Logs Location:** `./logs/deployment_YYYYMMDD_HHMMSS.log`

---

## 🔧 Configuration

### Environment Variables

Create a `.env` file (see `.env.example`):

```bash
# DuckDNS Configuration
DUCKDNS_DOMAIN="your-domain-here"
DUCKDNS_TOKEN="your-token-here"

# Let's Encrypt Configuration
LETSENCRYPT_EMAIL="your-email@example.com"

# Website Configuration
SITE_SOURCE_DIR="$HOME/site"
WEB_ROOT="/var/www/html"
```

### Alternative: Environment Variables

You can also set these as environment variables instead of using `.env`:

```bash
export DUCKDNS_DOMAIN="your-domain"
export DUCKDNS_TOKEN="your-token"
export LETSENCRYPT_EMAIL="you@email.com"
export SITE_SOURCE_DIR="$HOME/site"
```

---

## 🤖 GitHub Actions (CI/CD)

Automated deployment with GitHub Actions! Push changes and they're automatically deployed.

### Quick Setup

1. **Add secrets to your GitHub repository:**
   - Go to: Settings → Secrets and variables → Actions
   - Add: `SSH_PRIVATE_KEY`, `SSH_HOST`, `SSH_USER`
   - Add: `DUCKDNS_DOMAIN`, `DUCKDNS_TOKEN`, `LETSENCRYPT_EMAIL`

2. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "Enable auto-deploy"
   git push origin main
   ```

3. **Done!** Every push to `main` automatically deploys your website.

### Available Workflows

**1. Deploy Website** (Automatic)
- Triggers on push to `main` branch
- Deploys only when `site/` files change
- Fast incremental updates

**2. Full Stack Deployment** (Manual)
- Run from GitHub Actions tab
- Complete server setup with SSL
- Selectively skip steps

### Detailed Setup Guide

See [.github/SETUP.md](.github/SETUP.md) for complete instructions including:
- SSH key generation
- GitHub secrets configuration
- Troubleshooting
- Security best practices

---

## 📖 Detailed Usage Examples

### Example 1: First-Time Complete Setup

```bash
# 1. Configure environment
cp .env.example .env
nano .env

# 2. Prepare website
mkdir -p $HOME/site
cp -r /path/to/your/website/* $HOME/site/

# 3. Run full deployment
./full_deploy.sh
```

### Example 2: Update Website Content Only

```bash
# Update your website files
cp -r /path/to/updated/files/* $HOME/site/

# Deploy changes
./deploy-site.sh
```

### Example 3: Server Already Setup

```bash
# Skip server setup, only update DNS, deploy, and renew SSL
./full_deploy.sh --skip-server-setup
```

### Example 4: Rollback After Bad Deployment

```bash
# Rollback to previous version
./deploy-site.sh --rollback
```

### Example 5: Testing Without Executing

```bash
# See what would happen without making changes
./full_deploy.sh --dry-run
```

---

## 🔍 Verification Commands

### Check Nginx Status
```bash
sudo systemctl status nginx
sudo nginx -t  # Test configuration
```

### Check SSL Certificate
```bash
sudo certbot certificates
openssl s_client -connect yourdomain.duckdns.org:443
```

### Check DNS Records
```bash
dig yourdomain.duckdns.org
nslookup yourdomain.duckdns.org
```

### Test Website
```bash
curl http://yourdomain.duckdns.org
curl https://yourdomain.duckdns.org
```

### View Logs
```bash
# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Deployment logs
tail -f logs/deployment_*.log
```

---

## 🛡️ Security Features

- **Firewall Configuration** - UFW rules for SSH, HTTP, HTTPS
- **Automatic HTTPS** - Let's Encrypt SSL certificates
- **Secure Credentials** - No hardcoded tokens or passwords
- **File Permissions** - Proper ownership (www-data) and permissions
- **Input Validation** - IP validation, DNS verification, config validation

---

## 🔄 Backup and Rollback

### Automatic Backups
- Backups created before every deployment
- Stored in `/var/backups/nginx-sites/`
- Automatic rotation (keeps last 5 backups)
- Compressed with gzip

### Manual Rollback
```bash
./deploy-site.sh --rollback
```

### List Backups
```bash
ls -lh /var/backups/nginx-sites/
```

### Manual Restore
```bash
sudo tar -xzf /var/backups/nginx-sites/backup_YYYYMMDD_HHMMSS.tar.gz -C /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo systemctl reload nginx
```

---

## 📊 Monitoring and Maintenance

### Check Deployment Status
```bash
# View latest deployment log
tail -f logs/deployment_$(ls -t logs/ | head -n1)
```

### Certificate Renewal
Certbot automatically renews certificates. Test renewal:
```bash
sudo certbot renew --dry-run
```

### Update DNS Manually
```bash
./update_dns.sh
```

### Check Disk Space
```bash
df -h /var/www/html
df -h /var/backups/nginx-sites
```

---

## 🐛 Troubleshooting

### Issue: DNS Not Propagating

**Solution:**
```bash
# Check current DNS
dig yourdomain.duckdns.org

# Force update
./update_dns.sh

# Wait and check again (can take up to 10 minutes)
```

### Issue: SSL Certificate Failed

**Solution:**
```bash
# Ensure DNS is correct first
dig yourdomain.duckdns.org

# Try manual certificate
sudo certbot --nginx -d yourdomain.duckdns.org

# Check logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Issue: Nginx Won't Start

**Solution:**
```bash
# Check configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Check if port is in use
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443
```

### Issue: Permission Denied

**Solution:**
```bash
# Fix web root permissions
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type f -exec chmod 644 {} \;
sudo find /var/www/html -type d -exec chmod 755 {} \;
```

### Issue: Rollback Failed

**Solution:**
```bash
# Check available backups
ls -lh /var/backups/nginx-sites/

# Manual restore
sudo tar -xzf /var/backups/nginx-sites/backup_YYYYMMDD_HHMMSS.tar.gz -C /var/www/html/
```

---

## 📚 Learning Resources

For a comprehensive learning guide covering all concepts, see [LEARNING_GUIDE.md](LEARNING_GUIDE.md).

### Topics Covered:
- DNS and domain management
- Linux server administration
- Nginx web server configuration
- SSL/TLS certificates
- DevOps automation
- Bash scripting best practices

### External Resources:
- [Nginx Documentation](http://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [DuckDNS Setup](https://www.duckdns.org/spec.jsp)
- [UFW Firewall Guide](https://help.ubuntu.com/community/UFW)

---

## 🤝 Contributing

Improvements and suggestions are welcome! Some ideas:
- Support for other DNS providers (Cloudflare, Route53)
- Docker containerization
- Nginx configuration templates
- Monitoring and alerting integration
- CI/CD integration

---

## 📝 License

See [LICENSE](LICENSE) file for details.

---

## 🎯 Project Structure

```
.
├── .github/
│   ├── workflows/
│   │   ├── deploy.yml           # Automatic deployment on push
│   │   └── full-deploy.yml      # Manual full stack deployment
│   └── SETUP.md                 # GitHub Actions setup guide
├── site/                        # Your website files (deploy this)
│   ├── index.html
│   ├── assets/
│   └── css/
├── setup-server.sh              # Server setup and configuration
├── update_dns.sh                # DNS management (DuckDNS)
├── deploy-site.sh               # Website deployment with rollback
├── full_deploy.sh               # Complete orchestration pipeline
├── .env.example                 # Configuration template
├── .gitignore                   # Git ignore rules
├── README.md                    # This file
├── LEARNING_GUIDE.md            # Comprehensive learning guide
├── LICENSE                      # License information
└── logs/                        # Deployment logs (auto-created)
```

---

## ⚡ Quick Reference

```bash
# First time setup
cp .env.example .env && nano .env
./full_deploy.sh

# Update website
./deploy-site.sh

# Rollback website
./deploy-site.sh --rollback

# Update DNS only
./update_dns.sh

# Full deployment (skip server setup)
./full_deploy.sh --skip-server-setup

# Preview deployment
./full_deploy.sh --dry-run

# View logs
tail -f logs/deployment_*.log
```

---

**Made with ❤️ for learning DevOps and system administration**

For questions or issues, please check the troubleshooting section or refer to the learning guide.
  
  # Query nameserver
  dig example.com NS
  
  # Trace DNS resolution
  dig +trace example.com
  
  # Check specific nameserver
  dig @8.8.8.8 example.com
  ```
- **Status**: Not Started
- **What to look for**:
  - `ANSWER SECTION` should show your IP
  - Status should be `NOERROR`
  - Query time indicates DNS performance

---

#### Task 9: Verify Site Via Domain ✓
**Concepts**: DNS Propagation, HTTP Requests, Domain Validation
- **What you'll learn**: End-to-end web access via domain name
- **Testing**:
  ```bash
  # Check DNS resolution
  nslookup example.com
  
  # Test HTTP access
  curl http://example.com
  
  # From browser: visit http://example.com
  ```
- **Status**: Not Started
- **Troubleshooting**:
  - Wait for DNS propagation (up to 48 hours)
  - Use `dig` to verify DNS propagation
  - Check if domain resolves: `ping example.com`
  - Verify Nginx logs for requests

---

### Phase 5: Security & SSL/TLS

#### Task 10: Create Let's Encrypt Certificate & Configure Nginx ✓
**Concepts**: HTTPS, Let's Encrypt, SSL/TLS, Nginx Configuration
- **What you'll learn**: Certificate generation, HTTPS setup, automatic renewal
- **Installation**:
  ```bash
  # Install Certbot
  sudo apt install certbot python3-certbot-nginx -y
  
  # Generate certificate (standalone or nginx plugin)
  sudo certbot certonly --nginx -d example.com -d www.example.com
  
  # Or use standalone (stop Nginx first)
  sudo certbot certonly --standalone -d example.com -d www.example.com
  ```
- **Nginx Configuration** (`/etc/nginx/sites-available/default`):
  ```nginx
  server {
    listen 80;
    server_name example.com www.example.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
  }
  
  server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    
    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # Security headers
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Website files
    root /var/www/html;
    index index.html;
  }
  ```
- **Status**: Not Started
- **Automatic Renewal**:
  ```bash
  # Test renewal
  sudo certbot renew --dry-run
  
  # Cron job runs automatically (installed with certbot)
  ```

---

#### Task 11: Validate SSL with OpenSSL ✓
**Concepts**: SSL/TLS Certificates, OpenSSL, Certificate Details
- **What you'll learn**: Certificate validation, certificate chains, expiration dates
- **Commands**:
  ```bash
  # View certificate details
  openssl x509 -in /etc/letsencrypt/live/example.com/fullchain.pem -text -noout
  
  # Check certificate expiration
  openssl x509 -in /etc/letsencrypt/live/example.com/fullchain.pem -noout -dates
  
  # Test HTTPS connection
  openssl s_client -connect example.com:443
  
  # From local machine
  openssl s_client -connect example.com:443 -servername example.com
  
  # Check certificate chain
  openssl s_client -connect example.com:443 -showcerts
  ```
- **Status**: Not Started
- **What to verify**:
  - Issuer: Let's Encrypt
  - Subject: Your domain
  - Validity dates
  - Certificate chain complete

---

### Bonus: Self-Signed Certificate (Optional)

#### Task 12: Create & Test Self-Signed SSL Certificate ✓
**Concepts**: Self-Signed Certificates vs Trusted Certificates, Certificate Authority
- **What you'll learn**: Difference between self-signed and CA-signed certs
- **Generate Self-Signed Certificate**:
  ```bash
  # Generate private key and certificate (valid for 365 days)
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/self-signed.key \
    -out /etc/ssl/certs/self-signed.crt
  
  # Nginx configuration for self-signed
  ssl_certificate /etc/ssl/certs/self-signed.crt;
  ssl_certificate_key /etc/ssl/private/self-signed.key;
  ```
- **Status**: Not Started
- **Key Differences**:
  - **Let's Encrypt**: Trusted by all browsers, free, auto-renews
  - **Self-Signed**: Not trusted, certificate warnings in browser, good for learning
  - **Use Case**: Self-signed for testing/development, Let's Encrypt for production

---

## 🔧 Quick Reference Commands

### Linux/SSH
```bash
ssh -i key.pem ubuntu@IP              # Connect to server
sudo -l                               # Check sudo privileges
sudo su                               # Become root
```

### Nginx
```bash
sudo systemctl status nginx            # Check status
sudo systemctl start/stop/restart      # Control service
sudo nginx -t                          # Test config
sudo tail -f /var/log/nginx/access.log # View logs
```

### File Transfer
```bash
scp -i key.pem file.html ubuntu@IP:/tmp/
ssh ubuntu@IP "sudo mv /tmp/file.html /var/www/html/"
```

### DNS/Network
```bash
dig example.com                        # Query DNS
nslookup example.com                   # DNS lookup
ping example.com                       # Test connectivity
curl http://example.com                # Test HTTP
```

### SSL/Certificates
```bash
sudo certbot certonly --nginx -d example.com
openssl x509 -in cert.pem -text -noout
openssl s_client -connect example.com:443
```

---

## 📊 Progress Tracking

| Task | Status | Notes |
|------|--------|-------|
| 1. Buy Domain | Not Started | |
| 2. Spin Up Server | Not Started | |
| 3. SSH & Install Nginx | Not Started | |
| 4. Download HTML Files | Not Started | |
| 5. Copy Files via SCP | Not Started | |
| 6. Validate with IP | Not Started | |
| 7. Create A Record | Not Started | |
| 8. Use dig Command | Not Started | |
| 9. Verify via Domain | Not Started | |
| 10. Let's Encrypt Certificate | Not Started | |
| 11. Validate SSL | Not Started | |
| 12. Self-Signed Cert (Optional) | Not Started | |

---

## 🚀 Getting Started

**Next Steps**:
1. Read through the tasks above
2. Complete Task 1: Register a domain (this takes time)
3. While waiting for domain, complete Task 2: Provision a server
4. Once server is ready, begin with Task 3

**Tips for Success**:
- ✅ Keep detailed notes of your steps
- ✅ Test each phase before moving to the next
- ✅ Don't skip the "Key Concepts" sections
- ✅ Troubleshoot methodically using logs
- ✅ Document any errors and solutions

---

## 📚 Additional Resources

### DNS
- https://mxtoolbox.com/mxlookup.aspx - DNS lookup tool
- https://www.cloudflare.com/learning/dns/what-is-dns/ - DNS basics

### Nginx
- http://nginx.org/en/docs/ - Official Nginx documentation
- https://www.nginx.com/resources/wiki/start/ - Nginx starter guide

### Let's Encrypt
- https://letsencrypt.org/docs/ - Let's Encrypt documentation
- https://certbot.eff.org/ - Certbot documentation

### SSL/TLS
- https://www.ssl.com/article/what-is-an-ssl-certificate/ - SSL basics
- https://www.cloudflare.com/learning/ssl/what-is-an-ssl-certificate/ - SSL overview

### Linux/SSH
- https://linux.die.net/man/ - Linux man pages
- https://www.ssh.com/academy/ssh/command - SSH guide

---

## 📝 Notes & Issues

Use this section to document anything you learn or issues you encounter:

```
[Your notes here]
```

---

**Last Updated**: January 2, 2026
**Project Status**: Ready to Begin
