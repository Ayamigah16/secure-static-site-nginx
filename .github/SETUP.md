# GitHub Actions Setup Guide

This guide will help you set up automated deployments using GitHub Actions.

## 🔧 Prerequisites

1. Your code must be in a GitHub repository
2. You need SSH access to your server
3. Your server should have the deployment scripts already set up

---

## 📝 GitHub Secrets Configuration

You need to add the following secrets to your GitHub repository:

### Required Secrets

Go to: **Repository Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description | Example |
|------------|-------------|---------|
| `SSH_PRIVATE_KEY` | Your SSH private key | Contents of `~/.ssh/id_rsa` or `key.pem` |
| `SSH_HOST` | Server IP or hostname | `123.45.67.89` or `server.example.com` |
| `SSH_USER` | SSH username | `ubuntu` or `ec2-user` |
| `DUCKDNS_DOMAIN` | Your DuckDNS domain (without .duckdns.org) | `my-site` |
| `DUCKDNS_TOKEN` | Your DuckDNS token | `abc123-def456-ghi789` |
| `LETSENCRYPT_EMAIL` | Email for SSL certificates | `you@example.com` |

### Optional Secrets

| Secret Name | Description | Default |
|------------|-------------|---------|
| `DOMAIN` | Your full domain for verification | `my-site.duckdns.org` |

---

## 🔑 Setting Up SSH Key

### Option 1: Use Existing Key

If you already have an SSH key that can access your server:

```bash
# Display your private key
cat ~/.ssh/id_rsa
# or
cat /path/to/your/key.pem

# Copy the entire output (including BEGIN and END lines)
```

### Option 2: Create New Deployment Key

For better security, create a dedicated deployment key:

```bash
# Generate new SSH key pair
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_deploy_key

# Copy public key to server
ssh-copy-id -i ~/.ssh/github_deploy_key.pub ubuntu@YOUR_SERVER_IP

# Display private key for GitHub secret
cat ~/.ssh/github_deploy_key
```

**Important:** Copy the **entire private key** including the header and footer:
```
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

---

## 🚀 Workflows Available

### 1. **Deploy Website** (Automatic)
- **File:** `.github/workflows/deploy.yml`
- **Triggers:** Automatically on push to main/master branch when `site/` files change
- **What it does:** 
  - Syncs website files to server
  - Runs deployment script
  - Verifies website is accessible

### 2. **Full Stack Deployment** (Manual)
- **File:** `.github/workflows/full-deploy.yml`
- **Triggers:** Manual trigger via GitHub Actions UI
- **What it does:**
  - Complete server setup
  - DNS configuration
  - Website deployment
  - SSL certificate setup
- **Options:** Can skip individual steps

---

## 📖 Usage Examples

### Example 1: Automatic Deployment

Simply push changes to your website:

```bash
# Make changes to your website
echo "<h1>Updated!</h1>" > site/index.html

# Commit and push
git add site/
git commit -m "Update homepage"
git push origin main

# GitHub Actions will automatically deploy!
```

### Example 2: Manual Full Deployment

1. Go to **Actions** tab in GitHub
2. Select **Full Stack Deployment**
3. Click **Run workflow**
4. Choose options:
   - ☐ Skip server setup
   - ☐ Skip DNS update
   - ☐ Skip SSL setup
5. Click **Run workflow**

### Example 3: First-Time Setup

For the first deployment:

1. Set up all GitHub secrets
2. Push your code to GitHub
3. Trigger **Full Stack Deployment** manually
4. After that, automatic deployments will work

---

## 🔍 Monitoring Deployments

### View Workflow Status

1. Go to **Actions** tab in your GitHub repository
2. Click on the workflow run
3. View logs for each step

### Check Deployment Logs

On your server:
```bash
cd /home/ubuntu/secure-static-site-nginx
tail -f logs/deployment_*.log
```

---

## 🐛 Troubleshooting

### Issue: SSH Connection Failed

**Error:** "Permission denied (publickey)"

**Solutions:**
1. Verify SSH_PRIVATE_KEY secret contains the complete key
2. Ensure the key has access to your server:
   ```bash
   ssh -i ~/.ssh/your_key ubuntu@YOUR_SERVER_IP
   ```
3. Check SSH_USER and SSH_HOST are correct

### Issue: Deployment Script Failed

**Error:** "deploy-site.sh: command not found"

**Solutions:**
1. Ensure scripts are in the repository root
2. Check scripts are executable:
   ```bash
   chmod +x *.sh
   git add *.sh
   git commit -m "Make scripts executable"
   git push
   ```

### Issue: Website Not Updating

**Solutions:**
1. Check if workflow ran successfully in Actions tab
2. SSH into server and check deployment logs
3. Verify Nginx is running:
   ```bash
   sudo systemctl status nginx
   ```
4. Check file permissions:
   ```bash
   ls -la /var/www/html/
   ```

### Issue: SSL Certificate Error

**Error:** Certificate generation failed

**Solutions:**
1. Ensure DNS is propagated:
   ```bash
   dig your-domain.duckdns.org
   ```
2. Check domain resolves to correct IP
3. Try manual certificate:
   ```bash
   sudo certbot --nginx -d your-domain.duckdns.org
   ```

---

## 🔒 Security Best Practices

### 1. Protect Your Secrets
- Never commit `.env` files to git
- Use GitHub Secrets for sensitive data
- Rotate SSH keys periodically

### 2. Limit SSH Key Access
- Use dedicated deployment key
- Restrict key to specific commands (optional advanced setup)
- Use SSH key with passphrase for added security

### 3. Review Workflow Permissions
- Workflows run with limited permissions by default
- Only grant necessary permissions
- Review Actions logs regularly

### 4. Add `.gitignore`
Create `.gitignore` if not exists:
```
# Environment files
.env
.env.local

# Logs
logs/
*.log

# SSH keys
*.pem
*.key
id_rsa*

# Backups
*.tar.gz
backups/
```

---

## 📊 Workflow Configuration

### Customize Deployment Path

Edit workflow files to change deployment path:

```yaml
env:
  DEPLOY_PATH: /home/ubuntu/your-custom-path
```

### Customize Triggers

Edit `deploy.yml` to change when deployment runs:

```yaml
on:
  push:
    branches:
      - main
      - develop  # Add more branches
    paths:
      - 'site/**'
      - 'assets/**'  # Add more paths
```

### Add Notifications

Add Slack/Discord/Email notifications on deployment:

```yaml
- name: Notify Slack
  if: success()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "🚀 Deployment successful!"
      }
```

---

## 🎯 Testing Your Setup

### 1. Test SSH Connection Locally

```bash
ssh -i ~/.ssh/your_key $SSH_USER@$SSH_HOST "echo 'Connection successful'"
```

### 2. Test Deployment Manually

```bash
# On your server
cd /home/ubuntu/secure-static-site-nginx
./deploy-site.sh
```

### 3. Test Workflow Syntax

```bash
# Install act (GitHub Actions local runner)
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Test workflow locally
act -j deploy --secret-file .secrets
```

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [SSH Key Authentication](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

---

## ✅ Verification Checklist

Before pushing to GitHub:

- [ ] All secrets configured in GitHub repository
- [ ] SSH key has access to server
- [ ] Deployment scripts exist and are executable
- [ ] `.gitignore` configured properly
- [ ] Website files in `site/` directory
- [ ] `.env` file NOT committed to git

After first deployment:

- [ ] Workflow ran successfully
- [ ] Website is accessible
- [ ] HTTPS is working
- [ ] Future pushes trigger automatic deployment

---

**Need help?** Check the troubleshooting section or refer to the main README.md
