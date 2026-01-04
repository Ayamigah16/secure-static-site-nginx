#!/bin/bash
set -euo pipefail

# Update system
apt-get update
apt-get upgrade -y

# Create deployment user if not exists
if ! id -u ${deploy_user} >/dev/null 2>&1; then
    useradd -m -s /bin/bash ${deploy_user}
    usermod -aG sudo ${deploy_user}
    echo "${deploy_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${deploy_user}
fi

# Install basic utilities
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    vim \
    htop \
    net-tools \
    software-properties-common

# Set timezone
timedatectl set-timezone UTC

# Enable automatic security updates
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Create deployment directory
mkdir -p /home/${deploy_user}/secure-static-site-nginx
chown -R ${deploy_user}:${deploy_user} /home/${deploy_user}/secure-static-site-nginx

# Signal completion
echo "User data script completed successfully" > /var/log/user-data-completion.log
