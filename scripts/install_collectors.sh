#!/bin/bash

# ===================================================================================
# Script to install Node Exporter and Grafana Alloy, then configure them.
#
# This script will:
#   1. Create dedicated system users for each service.
#   2. Download, install, and configure systemd services for Node Exporter and Alloy.
#   3. Prompt for a Prometheus IP and generate a complete Alloy config file.
#   4. Start and enable the services.
#
# Supported OS: Debian / Ubuntu
# ===================================================================================

# --- Configuration ---
# You can change these versions to install a different release.
NODE_EXPORTER_VERSION="1.9.1"
ALLOY_VERSION="1.9.2" # Check for the latest Alloy version on GitHub
# --- End Configuration ---

# Stop on any error
set -e

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use 'sudo ./setup_monitoring_agents.sh'"
   exit 1
fi

echo "---[ Starting Node Exporter and Alloy Setup ]---"

# 1. Install dependencies
echo "STEP 1: Installing dependencies (curl, unzip)..."
apt-get update > /dev/null
apt-get install -y curl unzip > /dev/null

# 2. Install Node Exporter
echo "STEP 2: Installing Node Exporter v${NODE_EXPORTER_VERSION}..."
# Create a dedicated user for node_exporter
if ! id "node_exporter" &>/dev/null; then
    useradd --system --no-create-home --shell /bin/false node_exporter
fi

# Download and install
cd /tmp
curl -sSL "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" -o node_exporter.tar.gz
tar -xzf node_exporter.tar.gz
install -o root -g root -m 0755 "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/node_exporter
rm -rf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64" node_exporter.tar.gz

# Create systemd service file for Node Exporter
cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

echo "Node Exporter installed."

# 3. Install Grafana Alloy
echo "STEP 3: Installing Grafana Alloy v${ALLOY_VERSION}..."
# Create a dedicated user for alloy
if ! id "alloy" &>/dev/null; then
    useradd --system --no-create-home --shell /bin/false alloy
fi

# Create necessary directories
mkdir -p /etc/alloy /var/lib/alloy
chown -R alloy:alloy /etc/alloy /var/lib/alloy

# Download and install
cd /tmp
curl -sSL "https://github.com/grafana/alloy/releases/download/v${ALLOY_VERSION}/alloy-linux-amd64.zip" -o alloy.zip
unzip -q alloy.zip -d .
install -o root -g root -m 0755 alloy-linux-amd64 /usr/local/bin/alloy
rm -f alloy.zip alloy-linux-amd64

# Create systemd service file for Alloy
cat <<EOF > /etc/systemd/system/alloy.service
[Unit]
Description=Grafana Alloy
Wants=network-online.target
After=network-online.target

[Service]
User=alloy
Group=alloy
Type=simple
ExecStart=/usr/local/bin/alloy --config.file=/etc/alloy/config.alloy --storage.path=/var/lib/alloy

[Install]
WantedBy=multi-user.target
EOF

echo "Grafana Alloy installed."

# 4. Create the Alloy configuration file
echo "STEP 4: Creating Alloy configuration file..."
PROMETHEUS_IP=""
while [ -z "$PROMETHEUS_IP" ]; do
    read -p "Enter the IP address of your Prometheus server: " PROMETHEUS_IP
    if [ -z "$PROMETHEUS_IP" ]; then
        echo "IP address cannot be empty. Please try again."
    fi
done

# =================================================================
# Configuration file for Grafana Alloy with Prometheus integration
# =================================================================

cat <<EOF > /etc/alloy/config.alloy
logging {
    level  = "info"
    format = "logfmt"
}

// Define the destination for metrics (your Prometheus server)
prometheus.remote_write "default" {
    endpoint {
        url = "http://${PROMETHEUS_IP}:9090/api/v1/write"
    }
}

// Scrape Alloy's own internal metrics
prometheus.scrape "alloy_metrics_local" {
    targets    = [{"__address__" = "127.0.0.1:8080"}]
    forward_to = [prometheus.remote_write.default.receiver]
}

// Scrape this machine's metrics using Node Exporter
prometheus.scrape "node_exporter_local" {
    targets    = [{"__address__" = "localhost:9100"}]
    forward_to = [prometheus.remote_write.default.receiver]
}
EOF

# Set correct permissions for the config file
chown alloy:alloy /etc/alloy/config.alloy
chmod 640 /etc/alloy/config.alloy

echo "Configuration file created at /etc/alloy/config.alloy"

# 5. Start and enable services
echo "STEP 5: Starting and enabling services..."
systemctl daemon-reload
systemctl enable --now node_exporter.service
systemctl enable --now alloy.service

echo ""
echo "---[ Setup Complete! ]---"
echo ""
echo "✅ Node Exporter and Grafana Alloy are now installed and running."
echo ""
echo "You can check their status with:"
echo "   sudo systemctl status node_exporter"
echo "   sudo systemctl status alloy"
echo ""
echo "The Alloy configuration is located at: /etc/alloy/config.alloy"
echo ""