#!/bin/bash

# Update and upgrade system
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y git maven openjdk-${java_version}-jdk iptables-persistent terraform

# Clone and build application
sudo git clone ${github_repo} /home/ubuntu
sudo chown -R ubuntu:ubuntu /home/ubuntu
cd /home/ubuntu/tech_eazy_devops_atharva5683/terraform

# Initialize Terraform
terraform init

# Build with Maven
echo "Building with Maven..."
sudo mvn clean package

# Verify Java version
java_version_output=$(java -version 2>&1)
echo "Java version: $java_version_output"
echo "Expected: openjdk version \"21.0.2\" 2024-01-16"

# Test running the application
echo "Testing application startup..."
java -jar ${app_jar_path} --server.port=8080 &
app_pid=$!
sleep 10
kill $app_pid
echo "Application test complete"

# Configure port forwarding
sudo iptables -t nat -A PREROUTING -p tcp --dport ${target_port} -j REDIRECT --to-port 8080
sudo iptables -t nat -A OUTPUT -p tcp -o lo --dport ${target_port} -j REDIRECT --to-port 8080
sudo netfilter-persistent save

# Create service
cat << EOF | sudo tee /etc/systemd/system/app.service
[Unit]
Description=Spring Boot Application
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/app
ExecStart=/usr/bin/java -jar ${app_jar_path}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable app
sudo systemctl start app

# Auto-shutdown setup
echo "#!/bin/bash
sudo shutdown -h now" > /home/ubuntu/shutdown.sh
chmod +x /home/ubuntu/shutdown.sh
echo "*/5 * * * * if [ \$(( \$(date +%s) - \$(stat -c %Y /home/ubuntu/app/.git/FETCH_HEAD) )) -gt $(( ${auto_shutdown_minutes} * 60 )) ]; then /home/ubuntu/shutdown.sh; fi" | crontab -
