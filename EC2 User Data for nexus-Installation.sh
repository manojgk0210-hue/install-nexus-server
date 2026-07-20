#!/bin/bash

set -e

exec > /var/log/user-data.log 2>&1

echo "================================================="
echo "      Nexus Repository Installation"
echo "================================================="

apt update -y

apt install -y openjdk-21-jdk wget

cd /opt

rm -rf nexus
rm -rf sonatype-work
rm -f nexus-3.92.2-01-linux-x86_64.tar.gz

wget https://download.sonatype.com/nexus/3/nexus-3.92.2-01-linux-x86_64.tar.gz

tar -xzf nexus-3.92.2-01-linux-x86_64.tar.gz

mv nexus-3.92.2-01 nexus

# Create Nexus User
if ! id nexus >/dev/null 2>&1; then
    useradd -r -m -s /bin/bash nexus
fi

# Set Ownership
chown -R nexus:nexus /opt/nexus
chown -R nexus:nexus /opt/sonatype-work

# Reduce JVM Memory (Suitable for Small EC2 Instances)
sed -i 's/^-Xms.*/-Xms512m/' /opt/nexus/bin/nexus.vmoptions
sed -i 's/^-Xmx.*/-Xmx512m/' /opt/nexus/bin/nexus.vmoptions

# Create Systemd Service
cat > /etc/systemd/system/nexus.service <<EOF
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

systemctl daemon-reload
systemctl enable nexus
systemctl start nexus

echo "Waiting for Nexus to start..."

for i in {1..30}; do
    if [ -f /opt/sonatype-work/nexus3/admin.password ]; then
        break
    fi
    sleep 10
done

echo "================================================="
echo " Nexus Installation Completed"
echo "================================================="

echo "Nexus URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8081"

if [ -f /opt/sonatype-work/nexus3/admin.password ]; then
    echo "Username : admin"
    echo "Password :"
    cat /opt/sonatype-work/nexus3/admin.password
else
    echo "Nexus is still initializing."
    echo "Run the following command after a few minutes:"
    echo "cat /opt/sonatype-work/nexus3/admin.password"
fi
