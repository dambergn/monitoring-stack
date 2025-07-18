#!/bin/bash

# ===================================================================================
# Script to install Docker and Docker Compose Plugin on Debian-based systems
# (Proxmox 8 VE is based on Debian 12 'Bookworm')
#
# Run this inside a Proxmox CT or VM, NOT on the Proxmox host itself.
# ===================================================================================

# Stop on any error
set -e

echo "---[ Starting Docker and Docker Compose installation ]---"

# 1. Update package index and install dependencies
echo "STEP 1: Updating packages and installing dependencies..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# 2. Add Docker’s official GPG key
echo "STEP 2: Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 3. Set up the Docker repository
echo "STEP 3: Setting up the Docker APT repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Install Docker Engine, CLI, and Compose plugin
echo "STEP 4: Installing Docker Engine, CLI, and Compose plugin..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Add current user to the 'docker' group to run Docker without sudo
# This avoids having to use 'sudo' for every docker command.
echo "STEP 5: Adding current user ($USER) to the 'docker' group..."
sudo usermod -aG docker $USER

echo ""
echo "---[ Installation Complete! ]---"
echo ""
echo "✅ Docker and Docker Compose plugin have been installed successfully."
echo ""
echo "    >>> IMPORTANT ACTION REQUIRED <<<"
echo "You must log out and then log back in for the group changes to take effect."
echo "Alternatively, you can run the following command to apply the changes to your current session:"
echo "    newgrp docker"
echo ""
echo "After that, you can verify the installation by running:"
echo "    docker --version"
echo "    docker compose version"
echo ""