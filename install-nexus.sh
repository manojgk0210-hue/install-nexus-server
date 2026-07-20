#!/bin/bash

set -e

echo "================================================="
echo "      Nexus Repository Installation"
echo "================================================="

echo
echo "Updating packages..."
sudo apt update -y

echo
echo "Installing Java and wget..."
sudo apt install openjdk-21-jdk wget -y

echo
echo "Java Version"
java -version

echo
echo "Downloading Nexus..."

cd /opt

sudo rm -rf nexus
sudo rm -rf sonatype-work
sudo rm -f nexus-3.92.2-01-linux-x86_64.tar.gz

sudo wget https://download.sonatype.com/nexus/3/nexus-3.92.2-01-linux-x86_64.tar.gz

sudo tar -xzf nexus-3.92.2-01-linux-x86_64.tar.gz

sudo mv nexus-3.92.2-01 nexus

echo
echo "Creating Nexus User..."

if ! id nexus &>/dev/null
then
    sudo useradd -r -m -s /bin/bash nexus
fi

echo
echo "Setting Permissions..."

sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work

echo
echo "Creating Systemd Service..."

sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking

User=nexus
Group=nexus

LimitNOFILE=65536
LimitNPROC=4096

ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop

Restart=on-failure
TimeoutSec=600

[Install]
WantedBy=multi-user.target
EOF

echo
echo "Reloading systemd..."

sudo systemctl daemon-reload

echo
echo "Enabling Nexus..."

sudo systemctl enable nexus

echo
echo "Starting Nexus..."

sudo systemctl restart nexus

echo
echo "Waiting for Nexus to Start..."

sleep 60

echo
echo "Checking Nexus Status..."

if sudo systemctl is-active --quiet nexus
then
    echo "========================================"
    echo " Nexus Started Successfully"
    echo "========================================"
else
    echo "Nexus failed to start."
    sudo systemctl status nexus --no-pager
    exit 1
fi

echo
echo "========================================"
echo " Nexus Installation Completed"
echo "========================================"

echo
echo "Nexus URL"
echo "http://<EC2-PUBLIC-IP>:8081"

echo
echo "Default Username : admin"

echo
echo "Initial Password"

sudo cat /opt/sonatype-work/nexus3/admin.password

echo
echo "Useful Commands"

echo "sudo systemctl start nexus"
echo "sudo systemctl stop nexus"
echo "sudo systemctl restart nexus"
echo "sudo systemctl status nexus"
echo "sudo journalctl -u nexus -f"
