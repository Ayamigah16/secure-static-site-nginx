# Static Website with Nginx - Learning Guide

## 📚 Project Overview
This project teaches you how to deploy a static website using Nginx, configure DNS, and secure it with SSL certificates. You'll learn practical DevOps and system administration skills.

---

## 🎯 Learning Objectives

By completing this project, you will understand:
- **DNS**: Domain registration and A records
- **Linux**: Server management and command-line operations
- **Webserver**: Nginx configuration and deployment
- **SSL/TLS**: Certificate generation and HTTPS configuration
- **DevOps**: SCP file transfers, remote server management

---

## 📋 Project Tasks & Progress

### Phase 1: Domain & Server Setup

#### Task 1: Buy a Domain Name ✓
**Concepts**: DNS, Domain Registrars
- **What you'll learn**: How domain names work, registrars, domain configuration
- **Actions**:
  - Choose a registrar (Namecheap, GoDaddy, Route53, Cloudflare, etc.)
  - Buy a domain (e.g., `example.com`)
  - Note: Keep registrar credentials safe
- **Status**: Not Started
- **Tips**: 
  - Cheaper domains: `.tech`, `.xyz`, `.site` (instead of `.com`)
  - Some registrars offer free DNS management

---

#### Task 2: Spin Up a Ubuntu Server ✓
**Concepts**: Cloud Infrastructure, Linux Servers, EC2 (AWS), Droplets (DigitalOcean)
- **What you'll learn**: Cloud provider setup, server provisioning, security groups
- **Providers to consider**:
  - AWS EC2 (free tier available)
  - DigitalOcean (simple, cost-effective)
  - Linode, Vultr, or others
- **Server Requirements**:
  - OS: Ubuntu 20.04 LTS or newer
  - Size: t2.micro (AWS) or 512MB RAM minimum
  - Networking: Open ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **Status**: Not Started
- **Tips**:
  - Create a security group allowing SSH, HTTP, HTTPS
  - Save your .pem key file securely
  - Note the server's public IP address

---

### Phase 2: Server Configuration

#### Task 3: SSH into Server & Install Nginx ✓
**Concepts**: SSH, Linux Package Managers, Nginx
- **What you'll learn**: Remote server access, package installation, Linux commands
- **Commands to execute**:
  ```bash
  # Connect to server
  ssh -i /path/to/key.pem ubuntu@<SERVER_IP>
  
  # Update system packages
  sudo apt update
  sudo apt upgrade -y
  
  # Install Nginx
  sudo apt install nginx -y
  
  # Start and enable Nginx
  sudo systemctl start nginx
  sudo systemctl enable nginx
  
  # Verify installation
  sudo systemctl status nginx
  ```
- **Status**: Not Started
- **Key Concepts**:
  - `-i` flag specifies the private key
  - `sudo` executes commands as root
  - `systemctl` manages services

---

#### Task 4: Download HTML Website Files ✓
**Concepts**: HTML, File Downloads, Web Assets
- **What you'll learn**: Website structure, static file types
- **Options**:
  - Use a sample HTML template
  - Create a simple HTML file
  - Download from websites like HTML5UP, Bootstrap, etc.
- **Example**: Create a simple index.html:
  ```html
  <!DOCTYPE html>
  <html>
  <head>
    <title>My Website</title>
  </head>
  <body>
    <h1>Welcome to My Website</h1>
    <p>This site is running on Nginx!</p>
  </body>
  </html>
  ```
- **Status**: Not Started
- **Tips**:
  - Nginx serves files from `/var/www/html/` by default
  - Include CSS, JS, images for a complete learning experience

---

#### Task 5: Use SCP to Copy Files to Nginx Directory ✓
**Concepts**: SCP, Remote File Transfer, Linux Permissions
- **What you'll learn**: Secure file transfer, directory structure
- **Command syntax**:
  ```bash
  # Copy local file to server
  scp -i /path/to/key.pem /local/file.html ubuntu@<SERVER_IP>:/tmp/
  
  # Copy to Nginx directory (requires sudo on server)
  scp -i /path/to/key.pem /local/index.html ubuntu@<SERVER_IP>:/tmp/
  
  # On server, move to correct location
  sudo mv /tmp/index.html /var/www/html/
  sudo chmod 644 /var/www/html/index.html
  ```
- **Status**: Not Started
- **Key Concepts**:
  - SCP is SSH-based, uses same credentials
  - Must set correct permissions (644 for files, 755 for directories)
  - Path matters: remote path after the `:`

---

### Phase 3: Validation & Testing

#### Task 6: Validate Using Server IP Address ✓
**Concepts**: HTTP, Web Browsers, Network Connectivity
- **What you'll learn**: How web servers respond to requests
- **Testing methods**:
  ```bash
  # From local machine
  curl http://<SERVER_IP>
  
  # From browser
  # Visit: http://<SERVER_IP>
  ```
- **Status**: Not Started
- **Troubleshooting**:
  - Check security group allows port 80
  - Verify Nginx is running: `sudo systemctl status nginx`
  - Check file permissions
  - View Nginx logs: `sudo tail -f /var/log/nginx/access.log`

---

### Phase 4: DNS Configuration

#### Task 7: Create A Record in DNS & Point to Elastic IP ✓
**Concepts**: DNS Records, A Records, Elastic IPs
- **What you'll learn**: DNS mechanics, static IP allocation
- **Steps**:
  1. **Allocate Elastic IP** (AWS) or Static IP (DigitalOcean):
     ```bash
     # AWS: Allocate Elastic IP in Console
     # Associate with your EC2 instance
     ```
  2. **Add A Record in DNS**:
     - Go to domain registrar's DNS settings
     - Create A record:
       - **Name**: `@` (or leave blank for root)
       - **Type**: `A`
       - **Value**: Your Elastic/Static IP
       - **TTL**: 3600 (or default)
     - For `www` subdomain:
       - **Name**: `www`
       - **Type**: `A`
       - **Value**: Same Elastic/Static IP
- **Status**: Not Started
- **Key Concepts**:
  - A records map domain names to IPv4 addresses
  - TTL (Time To Live) = how long DNS result is cached
  - Propagation takes 5 minutes to 48 hours

---

#### Task 8: Use `dig` to Check DNS Records ✓
**Concepts**: DNS Queries, Dig Command, DNS Propagation
- **What you'll learn**: DNS verification, troubleshooting
- **Commands**:
  ```bash
  # Query A record
  dig example.com
  
  # Query specific record type
  dig example.com A
  
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
